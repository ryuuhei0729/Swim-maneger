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
    @events_by_date = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
      .group_by { |event| event.date }

    respond_to do |format|
      format.html
      format.js { 
        render partial: 'shared/calendar', locals: { 
          current_month: @current_month,
          events_by_date: @events_by_date
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
      redirect_to attendance_path, notice: '出席状況を更新しました。'
    else
      redirect_to attendance_path, alert: error_messages.join("\n")
    end
  end

  def event_status
    @event = AttendanceEvent.find(params[:event_id])
    @attendance = @event.attendance.includes(:user)
    render partial: 'shared/event_attendance_status', locals: { event: @event, attendance: @attendance }
  end

  private

  def attendance_params
    params.require(:attendance).permit(:status, :note)
  end
end 