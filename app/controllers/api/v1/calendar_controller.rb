class Api::V1::CalendarController < Api::V1::BaseController
  def show
    current_month = build_current_month
    
    # 指定月のイベントを取得
    attendance_events = AttendanceEvent.where(date: current_month.all_month).order(date: :asc)
    events = Event.where(date: current_month.all_month).order(date: :asc)
    
    render_success({
      year: current_month.year,
      month: current_month.month,
      month_name: current_month.strftime("%Y年%m月"),
      events_by_date: build_events_by_date(events, attendance_events, current_month),
      birthdays_by_date: build_birthdays_by_date(current_month),
      statistics: build_monthly_statistics(attendance_events, events, current_month)
    })
  end

  def update
    current_month = build_current_month_from_body
    
    # 指定月のイベントを取得
    attendance_events = AttendanceEvent.where(date: current_month.all_month).order(date: :asc)
    events = Event.where(date: current_month.all_month).order(date: :asc)
    
    render_success({
      year: current_month.year,
      month: current_month.month,
      month_name: current_month.strftime("%Y年%m月"),
      events_by_date: build_events_by_date(events, attendance_events, current_month),
      birthdays_by_date: build_birthdays_by_date(current_month),
      statistics: build_monthly_statistics(attendance_events, events, current_month)
    })
  end

  private

  def build_current_month
    if params[:year].present? && params[:month].present?
      Date.new(params[:year].to_i, params[:month].to_i, 1)
    else
      Date.current.beginning_of_month
    end
  end

  def build_current_month_from_body
    request_body = JSON.parse(request.body.read)
    if request_body["year"].present? && request_body["month"].present?
      Date.new(request_body["year"].to_i, request_body["month"].to_i, 1)
    else
      Date.current.beginning_of_month
    end
  end

  def build_events_by_date(events, attendance_events, current_month)
    events_by_date = {}

    # 一般イベントを追加
    events.each do |event|
      date_key = event.date.to_s
      events_by_date[date_key] ||= []
      events_by_date[date_key] << format_general_event(event)
    end

    # 出席イベントを追加
    attendance_events.each do |event|
      date_key = event.date.to_s
      events_by_date[date_key] ||= []
      events_by_date[date_key] << format_attendance_event(event)
    end

    events_by_date
  end

  def build_birthdays_by_date(current_month)
    birthdays_by_date = {}
    
    User.where(user_type: "player").each do |user|
      # 誕生日がnilの場合はスキップ
      next unless user.birthday
      
      # その月の誕生日を取得（年は考慮しない）
      birthday_this_month = Date.new(current_month.year, user.birthday.month, user.birthday.day)
      if birthday_this_month.month == current_month.month
        date_key = birthday_this_month.to_s
        birthdays_by_date[date_key] ||= []
        birthdays_by_date[date_key] << format_birthday_user(user, birthday_this_month)
      end
    end

    birthdays_by_date
  end

  def build_monthly_statistics(attendance_events, events, current_month)
    # 現在のユーザーの出席状況統計
    user_attendance = current_user_auth.user.attendance.joins(:attendance_event)
                        .where(attendance_events: { date: current_month.all_month })

    {
      total_events: events.count,
      total_attendance_events: attendance_events.count,
      competitions: attendance_events.where(is_competition: true).count,
      practices: attendance_events.where(is_competition: false).count,
      my_attendance_stats: {
        answered: user_attendance.count,
        present: user_attendance.where(status: "present").count,
        absent: user_attendance.where(status: "absent").count,
        other: user_attendance.where(status: "other").count,
        unanswered: attendance_events.count - user_attendance.count
      }
    }
  end

  def format_general_event(event)
    {
      id: event.id,
      title: event.title,
      type: "general_event",
      type_label: "一般イベント",
      date: event.date,
      place: event.place,
      note: event.note
    }
  end

  def format_attendance_event(event)
    user_attendance = current_user_auth.user.attendance.find_by(attendance_event: event)
    
    {
      id: event.id,
      title: event.title,
      type: "attendance_event",
      type_label: event.is_competition? ? "大会" : "練習",
      date: event.date,
      place: event.place,
      note: event.note,
      is_competition: event.is_competition,
      my_attendance: user_attendance ? {
        status: user_attendance.status,
        status_label: attendance_status_label(user_attendance.status),
        note: user_attendance.note
      } : nil
    }
  end

  def format_birthday_user(user, birthday_date)
    age = calculate_age(user.birthday)
    
    {
      id: user.id,
      name: user.name,
      generation: user.generation,
      birthday: birthday_date,
      age: age,
      turning_age: age + 1  # 誕生日になったら何歳になるか
    }
  end

  def calculate_age(birthday)
    today = Date.current
    age = today.year - birthday.year
    # 誕生日がまだ来ていない場合は1を引く
    age -= 1 if today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)
    age
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