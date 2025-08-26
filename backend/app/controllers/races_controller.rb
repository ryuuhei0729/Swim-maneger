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
    return render_entry_error("大会を選択してください。") unless params[:competition_id].present?
    
    selected_styles = params[:selected_styles] || {}
    return render_entry_error("エントリーする種目を選択してください。") if selected_styles.empty?

    begin
      success_count = process_entry_submission(selected_styles)
      render json: { success: true, message: "#{success_count}種目のエントリーを提出しました。" }
    rescue ActiveRecord::RecordInvalid => e
      render_entry_error("エントリーに失敗しました: #{e.message}")
    rescue => e
      Rails.logger.error "Entry submission failed: #{e.message}"
      render_entry_error("エラーが発生しました: #{e.message}")
    end
  end

  def delete_entry
    entry = current_user_auth.user.entries.find(params[:id])

    if entry.destroy
      render json: { success: true, message: "エントリーを削除しました。" }
    else
      render json: { success: false, message: "エントリーの削除に失敗しました。" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "エントリーが見つかりません。" }
  rescue => e
    Rails.logger.error "Entry deletion failed: #{e.message}"
    render json: { success: false, message: "システムエラーが発生しました。" }
  end

  def get_current_entries
    competition_id = params[:competition_id]
    
    entries = current_user_auth.user.entries
                                   .includes(:style)
                                   .by_event_id(competition_id)
    
    entries_data = entries.map do |entry|
      {
        style_id: entry.style_id,
        entry_time: entry.formatted_entry_time
      }
    end
    
    render json: { entries: entries_data }
  rescue => e
    Rails.logger.error "Failed to get current entries: #{e.message}"
    render json: { entries: [] }
  end

  private

  def process_entry_submission(selected_styles)
    event = Competition.find(params[:competition_id])
    user = current_user_auth.user
    
    Entry.transaction do
      # 既存のエントリーを削除
      user.entries.where(attendance_event: event).destroy_all
      
      # 新規エントリーを作成
      success_count = 0
      selected_styles.each do |style_id, time_str|
        next if time_str.blank?

        style = Style.find(style_id)
        entry_time = helpers.parse_time_to_seconds(time_str)

        Entry.create!(
          user: user,
          attendance_event: event,
          style: style,
          entry_time: entry_time
        )

        success_count += 1
      end
      
      success_count
    end
  end

  def render_entry_error(message)
    render json: { success: false, message: message }
  end

  # 時間フォーマット関連のヘルパーメソッドをinclude
  include TimeHelper
end
