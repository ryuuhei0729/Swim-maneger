class Api::V1::AttendanceController < Api::V1::BaseController
  def show
    current_month = parse_month_param
    
    # 今月・来月のイベントを取得
    this_month = current_month
    next_month = current_month.next_month

    this_month_events = AttendanceEvent.where(date: this_month.beginning_of_month..this_month.end_of_month).order(date: :asc)
    next_month_events = AttendanceEvent.where(date: next_month.beginning_of_month..next_month.end_of_month).order(date: :asc)

    # 現在のユーザーの出席情報を取得
    user_attendance = current_user_auth.user.attendance.where(attendance_event: this_month_events + next_month_events)
    answered_event_ids = user_attendance.pluck(:attendance_event_id)

    # 未回答のイベントのみを取得
    unanswered_this_month = this_month_events.where.not(id: answered_event_ids)
    unanswered_next_month = next_month_events.where.not(id: answered_event_ids)

    render_success({
      current_month: current_month.strftime("%Y-%m"),
      this_month: {
        events: this_month_events.map { |event| format_event_with_attendance(event) },
        unanswered_events: unanswered_this_month.map { |event| format_event(event) }
      },
      next_month: {
        events: next_month_events.map { |event| format_event_with_attendance(event) },
        unanswered_events: unanswered_next_month.map { |event| format_event(event) }
      },
      calendar_data: build_calendar_data(current_month)
    })
  end

  def update
    attendance_data = params.require(:attendance)
    updated_events = []
    errors = []

    attendance_data.each do |event_id, data|
      begin
        event = AttendanceEvent.find(event_id)
        attendance = current_user_auth.user.attendance.find_or_initialize_by(attendance_event: event)

        # バリデーション
        if data[:status].blank?
          errors << "#{event.title}の出席状況を選択してください。"
          next
        end

        if (data[:status] == "absent" || data[:status] == "other") && data[:note].blank?
          errors << "#{event.title}の備考を入力してください。"
          next
        end

        attendance.status = data[:status]
        attendance.note = data[:note]

        if attendance.save
          updated_events << {
            event_id: event.id,
            event_title: event.title,
            status: attendance.status,
            note: attendance.note
          }
        else
          errors << "#{event.title}の更新に失敗しました: #{attendance.errors.full_messages.join(', ')}"
        end
      rescue ActiveRecord::RecordNotFound
        errors << "イベントが見つかりません（ID: #{event_id}）"
      end
    end

    if errors.empty?
      render_success({
        updated_events: updated_events,
        message: "出席状況を更新しました"
      })
    else
              render_error("出席状況の更新中にエラーが発生しました", :unprocessable_content, { details: errors })
    end
  end

  def event_status
    event = AttendanceEvent.find(params[:event_id])
    attendance_list = event.attendances.includes(:user)

    render_success({
      event: format_event_detail(event),
      attendance_summary: build_attendance_summary(attendance_list),
      attendance_list: attendance_list.map { |attendance| format_attendance_detail(attendance) }
    })
  end

  private

  def parse_month_param
    if params[:month].present?
      begin
        Date.parse(params[:month])
      rescue Date::Error, ArgumentError
        Date.current
      end
    else
      Date.current
    end
  end

  def format_event(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      place: event.place,
      note: event.note,
      is_competition: event.is_competition,
      type_label: event.is_competition? ? "大会" : "練習"
    }
  end

  def format_event_with_attendance(event)
    user_attendance = current_user_auth.user.attendance.find_by(attendance_event: event)
    event_data = format_event(event)
    
    if user_attendance
      event_data[:my_attendance] = {
        status: user_attendance.status,
        status_label: attendance_status_label(user_attendance.status),
        note: user_attendance.note
      }
    else
      event_data[:my_attendance] = nil
    end

    event_data
  end

  def format_event_detail(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      place: event.place,
      note: event.note,
      is_competition: event.is_competition,
      type_label: event.is_competition? ? "大会" : "練習",
      total_participants: event.attendances.count
    }
  end

  def format_attendance_detail(attendance)
    {
      user: {
        id: attendance.user.id,
        name: attendance.user.name,
        generation: attendance.user.generation,
        user_type: attendance.user.user_type
      },
      status: attendance.status,
      status_label: attendance_status_label(attendance.status),
      note: attendance.note
    }
  end

  def build_attendance_summary(attendance_list)
    summary = attendance_list.group_by(&:status).transform_values(&:count)
    {
      present: summary["present"] || 0,
      absent: summary["absent"] || 0,
      other: summary["other"] || 0,
      total: attendance_list.count
    }
  end

  def build_calendar_data(current_month)
    # カレンダー表示用のデータ（STI構造では全てのイベントをEventテーブルから取得）
    all_events = Event
      .where(date: current_month.beginning_of_month..current_month.end_of_month)
      .order(date: :asc)

    # 誕生日データを取得
    birthdays_by_date = {}
    User.where(user_type: "player").each do |user|
      # 誕生日がnilの場合はスキップ
      next unless user.birthday
      
      begin
        birthday_this_month = Date.new(current_month.year, user.birthday.month, user.birthday.day)
        if birthday_this_month.month == current_month.month
          birthdays_by_date[birthday_this_month.to_s] ||= []
          birthdays_by_date[birthday_this_month.to_s] << {
            id: user.id,
            name: user.name,
            generation: user.generation
          }
        end
      rescue Date::Error, ArgumentError
        # 無効な誕生日データの場合はスキップ
        next
      end
    end

    # イベントを日付ごとにグループ化
    events_by_date = {}

    all_events.each do |event|
      events_by_date[event.date.to_s] ||= []
      
      if event.is_a?(AttendanceEvent) || event.is_a?(Competition)
        events_by_date[event.date.to_s] << {
          id: event.id,
          title: event.title,
          type: "attendance_event",
          place: event.place,
          note: event.note,
          is_competition: event.is_competition
        }
      else
        events_by_date[event.date.to_s] << {
          id: event.id,
          title: event.title,
          type: "general_event",
          place: event.place,
          note: event.note
        }
      end
    end

    {
      events_by_date: events_by_date,
      birthdays_by_date: birthdays_by_date
    }
  end

  def attendance_status_label(status)
    case status
    when "present"
      "出席"
    when "absent"
      "欠席"
    when "other"
      "その他"
    else
      "未定"
    end
  end
end 