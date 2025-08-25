class Api::V1::HomeController < Api::V1::BaseController
  def index
    render_success({
      calendar: build_calendar_data,
      announcements: build_announcements_data,
      today_birthdays: build_today_birthdays_data,
      best_times: build_best_times_data
    })
  end

  private

  def build_calendar_data
    current_month = Date.current
    attendance_events = AttendanceEvent
      .where(date: current_month.beginning_of_month..current_month.end_of_month)
      .order(date: :asc)

    events = Event
      .where(date: current_month.beginning_of_month..current_month.end_of_month)
      .order(date: :asc)

    # 誕生日データを取得
    birthdays_by_date = {}
    User.where(user_type: :player).each do |user|
      next unless user.birthday
      
      # その月の誕生日を取得（年は考慮しない）
      birthday_this_month = Date.new(current_month.year, user.birthday.month, user.birthday.day)
      if birthday_this_month.month == current_month.month
        date_key = birthday_this_month.to_s
        birthdays_by_date[date_key] ||= []
        birthdays_by_date[date_key] << format_birthday_user(user, birthday_this_month)
      end
    end

    # 両方のイベントを日付ごとにグループ化してマージ
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

    {
      year: current_month.year,
      month: current_month.month,
      month_name: current_month.strftime("%Y年%m月"),
      events_by_date: events_by_date,
      birthdays_by_date: birthdays_by_date,
      total_events: events.count + attendance_events.count
    }
  end

  def build_announcements_data
    announcements = Announcement.active
      .where("published_at <= ?", Time.current)
      .order(published_at: :desc)
      .limit(5) # 最新5件のみ

    announcements.map do |announcement|
      {
        id: announcement.id,
        title: announcement.title,
        content: announcement.content,
        published_at: announcement.published_at,
        formatted_published_at: announcement.published_at.strftime("%Y年%m月%d日 %H:%M"),
        is_recent: announcement.published_at > 3.days.ago
      }
    end
  end

  def build_today_birthdays_data
    today = Date.current
    birthday_users = User.where(
      "EXTRACT(month FROM birthday) = ? AND EXTRACT(day FROM birthday) = ?", 
      today.month, 
      today.day
    ).where(user_type: :player)

    birthday_users.map do |user|
      age = calculate_age(user.birthday)
      {
        id: user.id,
        name: user.name,
        generation: user.generation,
        birthday: user.birthday,
        age: age,
        turning_age: age + 1,
        profile_image_url: user.profile_image_url
      }
    end
  end

  def build_best_times_data
    players = User.where(user_type: :player).order(generation: :asc)
    male_players = players.select { |p| p.male? }
    female_players = players.select { |p| p.female? }
    
    styles = Style.all.map do |style|
      {
        id: style.name,
        title: style.name_jp,
        style: style.style,
        distance: style.distance,
        formatted_name: "#{style.name_jp} (#{style.distance}m)"
      }
    end

    # 各選手のベストタイムを取得
    best_times = {}
    players.each do |player|
      best_times[player.id] = {}
      styles.each do |style|
        best_record = player.records
          .joins(:style)
          .where(styles: { name: style[:id] })
          .order(:time)
          .first
        best_times[player.id][style[:id]] = {
          time: best_record&.time,
          formatted_time: format_swim_time(best_record&.time),
          record_id: best_record&.id,
          updated_at: best_record&.updated_at
        }
      end
    end

    # 世代別グループ化
    players_by_generation = group_players_by_generation(players, best_times)
    male_players_by_generation = group_players_by_generation(male_players, best_times)
    female_players_by_generation = group_players_by_generation(female_players, best_times)

    {
      styles: styles,
      players: {
        all: players_by_generation,
        male: male_players_by_generation,
        female: female_players_by_generation
      },
      statistics: {
        total_players: players.count,
        male_players: male_players.count,
        female_players: female_players.count,
        generations: players.map(&:generation).uniq.sort
      },
      default_tab: current_user_auth.user.male? ? "male" : "female"
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
      turning_age: age + 1
    }
  end

  def group_players_by_generation(players, best_times)
    players.group_by(&:generation).map do |generation, generation_players|
      {
        generation: generation,
        generation_label: "#{generation}期生",
        players: generation_players.map do |player|
          {
            id: player.id,
            name: player.name,
            generation: player.generation,
            gender: player.gender,
            gender_label: player.male? ? "男性" : "女性",
            profile_image_url: player.profile_image_url,
            best_times: best_times[player.id]
          }
        end
      }
    end.sort_by { |group| group[:generation] }
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
end 