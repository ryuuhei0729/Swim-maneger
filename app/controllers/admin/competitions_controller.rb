class Admin::CompetitionsController < Admin::BaseController
  def index
    # カンバンボード用：今日以降の大会のみ（エントリー管理用）
    @competitions = Competition.where('date >= ?', Date.current).order(date: :asc)
    
    # 結果入力用：全ての大会（過去の大会も含む）
    @all_competitions = Competition.order(date: :desc).limit(20)
    
    # エントリー受付中の大会を取得
    @collecting_entries = Competition.joins(:entries)
                                   .distinct
                                   .order(date: :desc)
  end

  def update_entry_status
    @competition = Competition.find(params[:id])
    
    # JSONパラメータからentry_statusを取得
    entry_status = params[:entry_status] || request.body.read
    
    if @competition.update(entry_status: entry_status)
      render json: { success: true, message: "エントリー受付状況を更新しました" }
    else
      render json: { success: false, message: "更新に失敗しました" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "大会が見つかりません" }
  end

  def result
    @competition = Competition.find(params[:id])
    # 結果入力画面用のデータを取得
    @entries = @competition.entries.includes(:user, :style).order('users.generation', 'users.name')
    
    # 各エントリーに対応するRecordを取得
    @records = {}
    @entries.each do |entry|
      record = Record.find_by(
        user_id: entry.user_id,
        attendance_event_id: entry.attendance_event_id,
        style_id: entry.style_id
      )
      @records[entry.id] = record
    end

    # 各選手のベストタイムを取得（保存された記録を除外）
    @best_times = {}
    @best_time_updated = {}
    @entries.each do |entry|
      # 現在の大会の記録を除外してベストタイムを計算
      best_record = entry.user.records
                        .where(style: entry.style)
                        .where.not(id: @records[entry.id]&.id)
                        .order(:time)
                        .first
      
      if best_record
        minutes = (best_record.time / 60).to_i
        seconds = (best_record.time % 60).round(2)
        if minutes > 0
          @best_times[entry.id] = "#{minutes}:#{format('%05.2f', seconds)}"
        else
          @best_times[entry.id] = format('%.2f', seconds)
        end
      else
        @best_times[entry.id] = nil
      end
      
      # ベストタイム更新の判定
      if @records[entry.id]&.time.present?
        current_best = best_record&.time
        if current_best.nil? || @records[entry.id].time < current_best
          @best_time_updated[entry.id] = true
        else
          @best_time_updated[entry.id] = false
        end
      else
        @best_time_updated[entry.id] = false
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません"
  end

  def save_results
    @competition = Competition.find(params[:id])
    
    ActiveRecord::Base.transaction do
      params.each do |key, value|
        if key.start_with?('record_time_') && value.present?
          entry_id = key.sub('record_time_', '').to_i
          entry = @competition.entries.find(entry_id)
          
          # 記録タイムを秒に変換
          time_in_seconds = parse_time_to_seconds(value)
          
          # Recordを作成または更新
          record = Record.find_or_initialize_by(
            user_id: entry.user_id,
            attendance_event_id: entry.attendance_event_id,
            style_id: entry.style_id
          )
          record.time = time_in_seconds
          record.save!
          
          # Split Timeを処理
          process_split_times(entry_id, record)
        end
      end
      
      redirect_to admin_competition_result_path(@competition), notice: "結果を保存しました"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません"
  rescue => e
    redirect_to admin_competition_result_path(@competition), alert: "結果の保存に失敗しました: #{e.message}"
  end

  def start_entry_collection
    @event = Competition.find(params[:event_id])
    
    # 既にエントリー受付中かチェック（実際にはフラグ等で管理することもできますが、
    # 今回はエントリーが1件でもあれば受付中とします）
    
    redirect_to admin_competition_path, notice: "#{@event.title}のエントリー受付を開始しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません。"
  end

  def show_entries
    Rails.logger.info "show_entries called with competition_id: #{params[:competition_id]}"
    @event = Competition.find(params[:competition_id])
    @entries = @event.entries
                    .includes(:user, :style)
                    .order('users.generation, users.name, styles.style, styles.distance')
    
    # 種目別に集計
    @entries_by_style = @entries.group_by(&:style)
    
    respond_to do |format|
      format.json do
        render json: {
          event: {
            id: @event.id,
            title: @event.title,
            date: @event.date.strftime("%Y年%m月%d日")
          },
          entries: @entries.map do |entry|
            {
              id: entry.id,
              user_name: entry.user.name,
              user_generation: entry.user.generation,
              style_name: entry.style.name_jp,
              entry_time: entry.formatted_entry_time,
              note: entry.note
            }
          end,
          entries_by_style: @entries_by_style.transform_values do |style_entries|
            style_entries.map do |entry|
              {
                id: entry.id,
                user_name: entry.user.name,
                user_generation: entry.user.generation,
                entry_time: entry.formatted_entry_time,
                note: entry.note,
                style_name: entry.style&.name_jp
              }
            end
          end
        }
      end
      format.html do
        render json: { error: "このアクションはJSON形式のみサポートしています" }, status: 406
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: "大会が見つかりません" }, status: 404 }
      format.html { render json: { error: "大会が見つかりません" }, status: 404 }
    end
  end

  private

  def parse_time_to_seconds(time_string)
    # "1:23.45" 形式のタイムを秒に変換
    if time_string.match?(/^\d+:\d+\.\d+$/)
      minutes, seconds = time_string.split(':')
      minutes.to_i * 60 + seconds.to_f
    elsif time_string.match?(/^\d+\.\d+$/)
      time_string.to_f
    else
      raise ArgumentError, "無効なタイム形式です: #{time_string}"
    end
  end

  def process_split_times(entry_id, record)
    # 既存のSplitTimeを削除
    record.split_times.destroy_all
    
    # Split Timeのパラメータを処理
    params.each do |key, value|
      if key.start_with?("split_distance_#{entry_id}_") && value.present?
        index = key.sub("split_distance_#{entry_id}_", "").to_i
        time_key = "split_time_#{entry_id}_#{index}"
        
        if params[time_key].present?
          distance = value.to_i
          time_in_seconds = parse_time_to_seconds(params[time_key])
          
          # SplitTimeを作成
          SplitTime.create!(
            record: record,
            distance: distance,
            split_time: time_in_seconds
          )
        end
      end
    end
  end

end 