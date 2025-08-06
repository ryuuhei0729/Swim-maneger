class RacesController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @records = @user.records.includes(:style, :attendance_event).order(created_at: :desc)

    # 大会ごとに記録をグルーピング（大会名＋日付でまとめる）
    @records_by_event = @records.group_by do |record|
      if record.attendance_event.present?
        [ record.attendance_event.title, record.attendance_event.date ]
      else
        [ "練習レース", record.created_at.to_date ]
      end
    end.sort_by { |(title, date), _| date }.reverse

    # 将来の大会を取得（エントリーの有無に関係なく）
    @future_events = Competition.where("date >= ?", Date.current)
                               .order(:date)
                               .includes(:entries)

    # 大会ごとにエントリー情報を整理
    @events_with_entries = @future_events.map do |event|
      user_entries = event.entries.where(user: @user)
      is_closed = event.entry_status == 'closed' || event.date < Date.current
      
      {
        event: event,
        entries: user_entries,
        is_closed: is_closed,
        has_entries: user_entries.any?
      }
    end

    # エントリー可能な大会を取得（将来の大会のみ、エントリー受付中のみ）
    @available_competitions = Competition.where("date >= ?", Date.current)
                                         .where(entry_status: :open)
                                         .order(:date)
                                         .limit(5)

    # 全種目を取得
    @all_styles = Style.all.order(:style, :distance)
  end

  def submit_entry
    @user = current_user_auth.user

    # バリデーション
    unless params[:competition_id].present?
      render json: { success: false, message: "大会を選択してください。" }
      return
    end

    @event = Competition.find(params[:competition_id])

    # 選択された種目とタイム
    selected_styles = params[:selected_styles] || {}

    if selected_styles.empty?
      render json: { success: false, message: "エントリーする種目を選択してください。" }
      return
    end

    begin
      Entry.transaction do
        # その大会の既存エントリーを全て削除
        deleted_count = @user.entries.where(attendance_event: @event).count
        @user.entries.where(attendance_event: @event).destroy_all
        
        # 新規エントリーを作成
        success_count = 0
        selected_styles.each do |style_id, time_str|
          next if time_str.blank?

          style = Style.find(style_id)

          # 時間を秒に変換
          entry_time = parse_time_to_seconds(time_str)

          # 新規エントリーを作成
          Entry.create!(
            user: @user,
            attendance_event: @event,
            style: style,
            entry_time: entry_time
          )

          success_count += 1
        end

        # 結果メッセージを表示
        if deleted_count > 0
          render json: {
            success: true,
            message: "#{success_count}種目のエントリーを提出しました。"
          }
        else
          render json: {
            success: true,
            message: "#{success_count}種目のエントリーを提出しました。"
          }
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { success: false, message: "エントリーに失敗しました: #{e.message}" }
    rescue => e
      render json: { success: false, message: "エラーが発生しました: #{e.message}" }
    end
  end

  def delete_entry
    @user = current_user_auth.user
    @entry = @user.entries.find(params[:id])

    if @entry.destroy
      render json: { success: true, message: "エントリーを削除しました。" }
    else
      render json: { success: false, message: "エントリーの削除に失敗しました。" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "エントリーが見つかりません。" }
  end

  def get_current_entries
    @user = current_user_auth.user
    competition_id = params[:competition_id]
    
    @entries = @user.entries.includes(:style)
                    .where(attendance_event_id: competition_id)
    
    entries_data = @entries.map do |entry|
      {
        style_id: entry.style_id,
        entry_time: entry.formatted_entry_time
      }
    end
    
    render json: { entries: entries_data }
  rescue => e
    render json: { entries: [] }
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
