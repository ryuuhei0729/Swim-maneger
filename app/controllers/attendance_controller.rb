class AttendanceController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @current_month = if params[:month].present?
      Date.parse(params[:month])
    else
      Date.current
    end

    # 今月・来月のイベントを取得
    this_month = @current_month
    next_month = @current_month.next_month

    this_month_events = AttendanceEvent.where(date: this_month.beginning_of_month..this_month.end_of_month).order(date: :asc)
    next_month_events = AttendanceEvent.where(date: next_month.beginning_of_month..next_month.end_of_month).order(date: :asc)

    # 現在のユーザーの出席情報を取得
    answered_event_ids = current_user_auth.user.attendance.where(attendance_event: this_month_events + next_month_events).pluck(:attendance_event_id)

    # 未回答のイベントのみを取得
    @this_month_events = this_month_events.where.not(id: answered_event_ids)
    @next_month_events = next_month_events.where.not(id: answered_event_ids)
    @attendance = current_user_auth.user.attendance.where(attendance_event: @this_month_events + @next_month_events)

    # カレンダー表示用のデータ
    attendance_events = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)

    events = Event
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)

    # ログインユーザーの出席情報を取得（カレンダー表示用）
    @user_attendance_by_event = {}
    current_user_auth.user.attendance
      .joins(:attendance_event)
      .where(attendance_events: { date: @current_month.beginning_of_month..@current_month.end_of_month })
      .each do |attendance|
        @user_attendance_by_event[attendance.attendance_event_id] = attendance
      end

    # 誕生日データを取得
    @birthdays_by_date = {}
    User.where(user_type: "player").each do |user|
      # その月の誕生日を取得（年は考慮しない）
      birthday_this_month = Date.new(@current_month.year, user.birthday.month, user.birthday.day)
      if birthday_this_month.month == @current_month.month
        @birthdays_by_date[birthday_this_month] ||= []
        @birthdays_by_date[birthday_this_month] << user
      end
    end

    # 両方のイベントを日付ごとにグループ化してマージ
    @events_by_date = {}

    # Eventを先に追加（上に表示される）
    events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end

    # AttendanceEventを後から追加（下に表示される）
    attendance_events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end

    respond_to do |format|
      format.html
      format.js {
        render partial: "shared/calendar", locals: {
          current_month: @current_month,
          events_by_date: @events_by_date,
          birthdays_by_date: @birthdays_by_date,
          user_attendance_by_event: @user_attendance_by_event
        }
      }
    end
  end

  def update_attendance
    attendance_params = params.require(:attendance)
    success = true
    error_messages = []

    attendance_params.each do |event_id, data|
      event = AttendanceEvent.find(event_id)
      attendance = current_user_auth.user.attendance.find_or_initialize_by(attendance_event: event)

      if data[:status].blank?
        error_messages << "#{event.title}の出席状況を選択してください。"
        success = false
        next
      end

      if (data[:status] == "absent" || data[:status] == "late") && data[:note].blank?
        error_messages << "#{event.title}の備考を入力してください。"
        success = false
        next
      end

      attendance.status = data[:status]
      attendance.note = data[:note]

      unless attendance.save
        error_messages << "#{event.title}の更新に失敗しました。"
        success = false
      end
    end

    if success
      redirect_to attendance_path, notice: "出席状況を更新しました。"
    else
      redirect_to attendance_path, alert: error_messages.join("\n")
    end
  end

  def edit
    @current_month = if params[:month].present?
      Date.parse(params[:month])
    else
      Date.current
    end

    # 今月・来月のイベントを取得（今日以降のみ）
    this_month = @current_month
    next_month = @current_month.next_month
    today = Date.current

    @this_month_events = AttendanceEvent.where(date: today..this_month.end_of_month).order(date: :asc)
    @next_month_events = AttendanceEvent.where(date: next_month.beginning_of_month..next_month.end_of_month).order(date: :asc)

    # 既存の出席情報を取得
    @user_attendance = {}
    current_user_auth.user.attendance
      .joins(:attendance_event)
      .where(attendance_events: { date: this_month.beginning_of_month..next_month.end_of_month })
      .each do |attendance|
        @user_attendance[attendance.attendance_event_id] = attendance
      end
  end

  def update
    attendance_params = params.require(:attendance)
    success = true
    error_messages = []

    attendance_params.each do |event_id, data|
      event = AttendanceEvent.find(event_id)
      attendance = current_user_auth.user.attendance.find_or_initialize_by(attendance_event: event)

      if data[:status].blank?
        error_messages << "#{event.title}の出席状況を選択してください。"
        success = false
        next
      end

      if (data[:status] == "absent" || data[:status] == "other") && data[:note].blank?
        error_messages << "#{event.title}の備考を入力してください。"
        success = false
        next
      end

      attendance.status = data[:status]
      attendance.note = data[:note]

      unless attendance.save
        error_messages << "#{event.title}の更新に失敗しました。"
        success = false
      end
    end

    if success
      redirect_to attendance_path, notice: "出席状況を更新しました。"
    else
      redirect_to edit_attendance_path, alert: error_messages.join("\n")
    end
  end

  def save_individual
    begin
      event = AttendanceEvent.find(params[:event_id])
      attendance = current_user_auth.user.attendance.find_or_initialize_by(attendance_event: event)

      if params[:status].blank?
        render json: { success: false, message: "出席状況を選択してください。" }
        return
      end

      if (params[:status] == "absent" || params[:status] == "other") && params[:note].blank?
        render json: { success: false, message: "欠席・その他の場合は備考を入力してください。" }
        return
      end

      attendance.status = params[:status]
      attendance.note = params[:note]

      if attendance.save
        render json: { 
          success: true, 
          message: "出席状況を更新しました。",
          attendance: {
            status: attendance.status,
            note: attendance.note
          }
        }
      else
        render json: { 
          success: false, 
          message: "更新に失敗しました: #{attendance.errors.full_messages.join(', ')}" 
        }
      end
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: "イベントが見つかりません。" }
    rescue => e
      render json: { success: false, message: "エラーが発生しました: #{e.message}" }
    end
  end

  def event_status
    @event = AttendanceEvent.find(params[:event_id])
    @attendance = @event.attendance.includes(:user)
    render partial: "shared/event_attendance_status", locals: { event: @event, attendance: @attendance }
  end

  private

  def attendance_params
    params.require(:attendance).permit(:status, :note)
  end
end
