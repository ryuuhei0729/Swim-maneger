class Api::V1::Admin::CompetitionsController < Api::V1::Admin::BaseController
  before_action :set_competition, only: [:show, :update_entry_status, :result, :save_results]

  # GET /api/v1/admin/competitions
  def index
    # 今日以降の大会（エントリー管理用）
    upcoming_competitions = Competition.where('date >= ?', Date.current).order(date: :asc)
    
    # 全ての大会（結果入力用、過去20件）
    all_competitions = Competition.order(date: :desc).limit(20)
    
    # エントリー受付中の大会
    collecting_entries = Competition.where(entry_status: :open)
                                   .distinct
                                   .order(date: :desc)

    render_success({
      upcoming_competitions: upcoming_competitions.map { |comp| serialize_competition(comp) },
      all_competitions: all_competitions.map { |comp| serialize_competition(comp) },
      collecting_entries: collecting_entries.map { |comp| serialize_competition(comp) }
    })
  end

  # GET /api/v1/admin/competitions/:id
  def show
    render_success({
      competition: serialize_competition_detail(@competition)
    })
  end

  # PATCH /api/v1/admin/competitions/:id/entry_status
  def update_entry_status
    entry_status = params[:entry_status]
    
    unless Competition.entry_statuses.key?(entry_status)
      return render_error("無効なエントリー状況です", status: :bad_request)
    end

    if @competition.update(entry_status: entry_status)
      render_success({
        competition: serialize_competition(@competition)
      }, "エントリー受付状況を更新しました")
    else
      render_error("エントリー状況の更新に失敗しました", status: :unprocessable_entity, errors: @competition.errors.as_json)
    end
  end

  # GET /api/v1/admin/competitions/:id/result
  def result
    # エントリーと関連データを取得
    entries = @competition.entries.joins(:user, :style).includes(:user, :style).references(:user, :style).order('users.generation', 'users.name')
    
    # 現在の大会の記録を事前に取得
    current_records = Record.where(
      attendance_event_id: @competition.id
    ).includes(:split_times).index_by { |record| [record.user_id, record.style_id] }
    
    # ベストタイムを事前に計算（現在の大会の記録を除外）
    user_ids = entries.map(&:user_id).uniq
    style_ids = entries.map(&:style_id).uniq
    
    best_records = Record.joins(:user, :style)
                        .where(user_id: user_ids, style_id: style_ids)
                        .where.not(attendance_event_id: @competition.id)
                        .select('DISTINCT ON (user_id, style_id) *')
                        .order(:user_id, :style_id, :time)
                        .includes(:split_times)
                        .index_by { |record| [record.user_id, record.style_id] }
    
    # 各エントリーの記録情報を構築
    entries_with_records = entries.map do |entry|
      record = current_records[[entry.user_id, entry.style_id]]
      best_record = best_records[[entry.user_id, entry.style_id]]
      
      best_time_formatted = nil
      if best_record
        best_time_formatted = format_time(best_record.time)
      end
      
      # ベストタイム更新の判定
      is_best_time_updated = false
      if record&.time.present?
        current_best = best_record&.time
        is_best_time_updated = current_best.nil? || record.time < current_best
      end

      {
        id: entry.id,
        user: {
          id: entry.user.id,
          name: entry.user.name,
          generation: entry.user.generation
        },
        style: {
          id: entry.style.id,
          name_jp: entry.style.name_jp,
          distance: entry.style.distance
        },
        entry_time: entry.formatted_entry_time,
        record: record ? {
          id: record.id,
          time: record.time,
          formatted_time: format_time(record.time),
          note: record.note,
          split_times: record.split_times.map do |split|
            {
              distance: split.distance,
              split_time: split.split_time,
              formatted_time: format_time(split.split_time)
            }
          end
        } : nil,
        best_time: best_time_formatted,
        is_best_time_updated: is_best_time_updated
      }
    end

    render_success({
      competition: serialize_competition(@competition),
      entries: entries_with_records
    })
  end

  # POST /api/v1/admin/competitions/:id/save_results
  def save_results
    unless params[:results].present?
      return render_error("結果データが提供されていません", status: :bad_request)
    end

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      params[:results].each do |result_data|
        begin
          entry_id = result_data[:entry_id]
          time_value = result_data[:time]
          note = result_data[:note]
          split_times = result_data[:split_times] || []

          next unless entry_id.present? && time_value.present?

          entry = @competition.entries.find(entry_id)
          time_in_seconds = parse_time_to_seconds(time_value.to_s)

          # Recordを作成または更新
          record = Record.find_or_initialize_by(
            user_id: entry.user_id,
            attendance_event_id: entry.attendance_event_id,
            style_id: entry.style_id
          )
          record.time = time_in_seconds
          record.note = note
          record.save!

          # Split Timesを処理
          record.split_times.destroy_all
          split_times.each do |split_data|
            if split_data[:distance].present? && split_data[:time].present?
              SplitTime.create!(
                record: record,
                distance: split_data[:distance].to_i,
                split_time: parse_time_to_seconds(split_data[:time].to_s)
              )
            end
          end

          success_count += 1
        rescue => e
          error_count += 1
          errors << "エントリーID #{entry_id}: #{e.message}"
        end
      end

      if error_count > 0
        raise ActiveRecord::Rollback
      end
    end

    if error_count > 0
      render_error("結果の保存中にエラーが発生しました", status: :unprocessable_entity, errors: errors)
    else
      render_success({
        saved_count: success_count
      }, "#{success_count}件の結果を保存しました")
    end
  end

  # GET /api/v1/admin/competitions/:competition_id/entries
  def show_entries
    competition = Competition.find(params[:competition_id])
    entries = competition.entries
                        .includes(:user, :style)
                        .order('users.generation, users.name, styles.style, styles.distance')

    # 種目別に集計
    entries_by_style = entries.group_by(&:style)

    render_success({
      competition: {
        id: competition.id,
        title: competition.title,
        date: competition.date,
        formatted_date: competition.date.strftime("%Y年%m月%d日")
      },
      entries: entries.map do |entry|
        {
          id: entry.id,
          user: {
            id: entry.user.id,
            name: entry.user.name,
            generation: entry.user.generation
          },
          style: {
            id: entry.style.id,
            name_jp: entry.style.name_jp,
            distance: entry.style.distance
          },
          entry_time: entry.formatted_entry_time,
          note: entry.note
        }
      end,
      entries_by_style: entries_by_style.transform_keys { |style| 
        style.name_jp 
      }.transform_values do |style_entries|
        style_entries.map do |entry|
          {
            id: entry.id,
            user_name: entry.user.name,
            user_generation: entry.user.generation,
            entry_time: entry.formatted_entry_time,
            note: entry.note
          }
        end
      end
    })
  end

  # POST /api/v1/admin/competitions/entry/start
  def start_entry_collection
    event = Competition.find(params[:event_id])
    
    # エントリー受付開始処理（entry_statusをopenに変更）
    if event.update(entry_status: :open)
      render_success({
        competition: serialize_competition(event)
      }, "#{event.title}のエントリー受付を開始しました")
    else
      render_error("エントリー受付の開始に失敗しました", status: :unprocessable_entity, errors: event.errors.as_json)
    end
  end

  private

  def set_competition
    @competition = Competition.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("大会が見つかりません", status: :not_found)
  end

  def serialize_competition(competition)
    {
      id: competition.id,
      title: competition.title,
      date: competition.date,
      place: competition.place,
      note: competition.note,
      entry_status: competition.entry_status,
      attendance_status: competition.attendance_status,
      is_competition: competition.is_competition,
      created_at: competition.created_at,
      updated_at: competition.updated_at,
      entries_count: competition.entries.count
    }
  end

  def serialize_competition_detail(competition)
    serialize_competition(competition).merge({
      entries: competition.entries.includes(:user, :style).map do |entry|
        {
          id: entry.id,
          user: {
            id: entry.user.id,
            name: entry.user.name,
            generation: entry.user.generation
          },
          style: {
            id: entry.style.id,
            name_jp: entry.style.name_jp,
            distance: entry.style.distance
          },
          entry_time: entry.formatted_entry_time,
          note: entry.note
        }
      end
    })
  end

  def format_time(time_seconds)
    return "" if time_seconds.blank?
    
    minutes = (time_seconds / 60).to_i
    seconds = (time_seconds % 60)
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end

  def parse_time_to_seconds(time_string)
    return nil if time_string.blank?
    
    # "1:23.45" 形式のタイムを秒に変換
    if time_string.match?(/^\d+:\d+\.?\d*$/)
      parts = time_string.split(':')
      minutes = parts[0].to_i
      seconds = parts[1].to_f
      minutes * 60 + seconds
    elsif time_string.match?(/^\d+\.?\d*$/)
      time_string.to_f
    else
      raise ArgumentError, "無効なタイム形式です: #{time_string}"
    end
  end
end
