class RecordsController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @records = @user.records.includes(:style, :attendance_event).order(created_at: :desc)

    # 大会ごとに記録をグルーピング
    @records_by_event = @records.group_by(&:attendance_event)
                               .sort_by { |event, records| 
                                 if event.present?
                                   event.date
                                 else
                                   records.first.created_at
                                 end
                               }
                               .reverse

    # 各種目のベストタイムを取得
    @best_times = {}
    Style.all.each do |style|
      best_record = @user.records
        .joins(:style)
        .where(styles: { name: style.name })
        .order(:time)
        .first
      @best_times[style.name] = best_record&.time
    end
    
    # ベストタイムのnoteを取得
    @best_time_notes = @user.best_time_notes
    
    # エントリー可能な大会を取得（将来の大会のみ）
    @available_competitions = AttendanceEvent.where(is_competition: true)
                                           .where('date >= ?', Date.current)
                                           .order(:date)
                                           .limit(5)
    
    # 全種目を取得
    @all_styles = Style.all.order(:style, :distance)
  end

  def submit_entry
    @user = current_user_auth.user
    
    # バリデーション
    unless params[:event_id].present?
      render json: { success: false, message: "大会を選択してください。" }
      return
    end
    
    @event = AttendanceEvent.find(params[:event_id])
    
    # 選択された種目とタイム
    selected_styles = params[:selected_styles] || {}
    
    if selected_styles.empty?
      render json: { success: false, message: "エントリーする種目を選択してください。" }
      return
    end
    
    begin
      Entry.transaction do
        success_count = 0
        
        selected_styles.each do |style_id, time_str|
          next if time_str.blank?
          
          style = Style.find(style_id)
          
          # 時間を秒に変換
          entry_time = parse_time_to_seconds(time_str)
          
          # 既存のエントリーがあるかチェック
          existing_entry = Entry.find_by(user: @user, attendance_event: @event, style: style)
          
          if existing_entry
            existing_entry.update!(entry_time: entry_time)
          else
            Entry.create!(
              user: @user,
              attendance_event: @event,
              style: style,
              entry_time: entry_time
            )
          end
          
          success_count += 1
        end
        
        render json: { 
          success: true, 
          message: "#{success_count}種目のエントリーを提出しました。" 
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { success: false, message: "エントリーに失敗しました: #{e.message}" }
    rescue => e
      render json: { success: false, message: "エラーが発生しました: #{e.message}" }
    end
  end

  private

  def format_time_display(seconds)
    return "-" if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round(2)

    if minutes.zero?
      sprintf("%05.2f", remaining_seconds)
    else
      sprintf("%d:%05.2f", minutes, remaining_seconds)
    end
  end

  def parse_time_to_seconds(time_str)
    return 0.0 if time_str.blank?
    
    # MM:SS.ss または SS.ss 形式をパース
    if time_str.include?(":")
      minutes, seconds_part = time_str.split(":", 2)
      minutes.to_i * 60 + seconds_part.to_f
    else
      time_str.to_f
    end
  end
  
  def format_time(seconds)
    return "-" if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round(2)

    if minutes.zero?
      sprintf("%05.2f", remaining_seconds)
    else
      sprintf("%d:%05.2f", minutes, remaining_seconds)
    end
  end
  
  helper_method :format_time_display, :format_time
end 