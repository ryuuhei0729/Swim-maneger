class Api::V1::MypageController < Api::V1::BaseController
  def show
    user = current_user_auth.user
    records = user.records.includes(:style, :attendance_event).order(created_at: :desc)

    # 各種目のベストタイムを取得
    best_times = {}
    Style.all.each do |style|
      best_record = user.records
        .joins(:style)
        .where(styles: { name: style.name })
        .order(:time)
        .first
      best_times[style.name] = {
        time: best_record&.time,
        formatted_time: format_swim_time(best_record&.time),
        record_id: best_record&.id,
        updated_at: best_record&.updated_at
      }
    end

    render_success({
      profile: build_profile_data(user),
      records: build_records_data(records),
      best_times: best_times,
      statistics: build_user_statistics(user, records)
    })
  end

  def update
    user = current_user_auth.user

    # 画像形式のチェック（Base64の場合）
    if params[:avatar_base64].present?
      unless valid_base64_image?(params[:avatar_base64])
        render_error("JPGまたはPNG形式の画像のみアップロード可能です", :unprocessable_entity)
        return
      end
    end

    # アバター画像の処理
    if params[:avatar_base64].present?
      begin
        decoded_image = decode_base64_image(params[:avatar_base64])
        user.avatar.attach(decoded_image)
      rescue => e
        render_error("画像の処理に失敗しました: #{e.message}", :unprocessable_entity)
        return
      end
    end

    # プロフィール情報の更新
    if user.update(user_params)
      render_success({
        message: "プロフィールを更新しました",
        profile: build_profile_data(user.reload)
      })
    else
      render_error("プロフィールの更新に失敗しました", :unprocessable_entity, user.errors)
    end
  end

  private

  def build_profile_data(user)
    {
      id: user.id,
      name: user.name,
      email: user.user_auth.email,
      user_type: user.user_type,
      user_type_label: user_type_label(user.user_type),
      generation: user.generation,
      generation_label: user.generation > 0 ? "#{user.generation}期生" : "スタッフ",
      gender: user.gender,
      gender_label: gender_label(user.gender),
      birthday: user.birthday,
      age: user.birthday ? calculate_age(user.birthday) : nil,
      bio: user.bio,
      avatar_url: user.avatar.attached? ? rails_blob_url(user.avatar) : nil,
      profile_image_url: user.profile_image_url,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end

  def build_records_data(records)
    records.limit(50).map do |record| # 最新50件に制限
      {
        id: record.id,
        time: record.time,
        formatted_time: format_swim_time(record.time),
        style: {
          id: record.style.id,
          name: record.style.name,
          name_jp: record.style.name_jp,
          distance: record.style.distance,
          style: record.style.style
        },
        attendance_event: record.attendance_event ? {
          id: record.attendance_event.id,
          title: record.attendance_event.title,
          date: record.attendance_event.date,
          is_competition: record.attendance_event.is_competition
        } : nil,
        created_at: record.created_at,
        updated_at: record.updated_at,
        is_best_time: is_best_time_for_style?(record)
      }
    end
  end

  def build_user_statistics(user, records)
    total_records = records.count
    best_times_count = Style.all.count { |style| 
      user.records.joins(:style).where(styles: { name: style.name }).exists?
    }
    
    recent_records = records.where('created_at >= ?', 30.days.ago)
    competition_records = records.joins(:attendance_event)
                                .where(attendance_events: { is_competition: true })

    {
      total_records: total_records,
      recent_records_count: recent_records.count,
      competition_records_count: competition_records.count,
      best_times_count: best_times_count,
      total_styles: Style.count,
      completion_rate: (best_times_count.to_f / Style.count * 100).round(1),
      latest_record_date: records.first&.created_at,
      records_this_month: records.where('created_at >= ?', Time.current.beginning_of_month).count
    }
  end

  def is_best_time_for_style?(record)
    best_record = current_user_auth.user.records
      .joins(:style)
      .where(styles: { name: record.style.name })
      .order(:time)
      .first
    
    best_record&.id == record.id
  end

  def user_params
    params.permit(:bio)
  end

  def user_type_label(user_type)
    case user_type
    when "director"
      "ディレクター"
    when "coach" 
      "コーチ"
    when "player"
      "選手"
    else
      "不明"
    end
  end

  def gender_label(gender)
    case gender
    when "male"
      "男性"
    when "female"
      "女性"
    when "other"
      "その他"
    else
      "未設定"
    end
  end

  def calculate_age(birthday)
    today = Date.current
    age = today.year - birthday.year
    # 誕生日がまだ来ていない場合は1を引く
    age -= 1 if today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)
    age
  end

  def format_swim_time(time_in_seconds)
    return nil unless time_in_seconds
    
    minutes = (time_in_seconds / 60).to_i
    seconds = time_in_seconds % 60
    
    if minutes > 0
      "#{minutes}:#{sprintf('%05.2f', seconds)}"
    else
      sprintf('%.2f', seconds)
    end
  end

  def valid_base64_image?(base64_string)
    # Base64の画像データ形式をチェック
    return false unless base64_string.start_with?('data:image/')
    
    # JPEG/PNG形式のみ許可
    base64_string.start_with?('data:image/jpeg;base64,') || 
    base64_string.start_with?('data:image/png;base64,')
  end

  def decode_base64_image(base64_string)
    # データURL形式から実際のBase64データを抽出
    base64_data = base64_string.split(',')[1]
    
    # MIME typeを取得
    mime_type = base64_string.match(/data:(.*?);base64,/)[1]
    extension = mime_type.split('/')[1]
    
    # ファイル名を生成
    filename = "avatar_#{Time.current.to_i}.#{extension}"
    
    # デコードしてStringIOオブジェクトを作成
    decoded_data = Base64.decode64(base64_data)
    
    {
      io: StringIO.new(decoded_data),
      filename: filename,
      content_type: mime_type
    }
  end
end 