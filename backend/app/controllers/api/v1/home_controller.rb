class Api::V1::HomeController < Api::V1::BaseController
  def index
    render_success({
      calendar: CacheService.cache_events_list(Date.current.beginning_of_month, nil) { build_calendar_data },
      announcements: CacheService.cache_announcements(true) { build_announcements_data },
      today_birthdays: build_today_birthdays_data,
      best_times: CacheService.cache_statistics('best_times') { build_best_times_data }
    })
  end

  private

  def build_calendar_data
    events = Event.where(date: Date.current.beginning_of_month..Date.current.end_of_month)
                  .order(:date)
    
    events.map { |event| event_serializer(event) }
  end

  def build_announcements_data
    announcements = Announcement.where(is_active: true)
                               .where('published_at <= ?', Time.current)
                               .order(published_at: :desc)
                               .limit(5)
    
    announcements.map { |announcement| announcement_serializer(announcement) }
  end

  def build_today_birthdays_data
    today = Date.current
    birthday_users = User.where(user_type: 'player')
                        .where("EXTRACT(month FROM birthday) = ? AND EXTRACT(day FROM birthday) = ?", 
                               today.month, today.day)
                        .order(:name)
    
    birthday_users.map { |user| birthday_user_serializer(user) }
  end

  def build_best_times_data
    best_records = Record.includes(:style)
                        .group(:style_id)
                        .select('style_id, MIN(time) as min_time')
                        .map do |min_record|
      record = Record.includes(:style)
                    .where(style_id: min_record.style_id)
                    .where(time: min_record.min_time)
                    .first
      
      {
        style: record.style,
        record: record
      }
    end
    
    best_records.map { |best_record_data| best_record_serializer(best_record_data) }
  end

  def format_swim_time(time_in_seconds)
    return nil if time_in_seconds.blank?
    
    minutes = (time_in_seconds / 60).to_i
    seconds = time_in_seconds % 60
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end

  def announcement_serializer(announcement)
    {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      published_at: announcement.published_at,
      is_active: announcement.is_active
    }
  end

  def birthday_user_serializer(user)
    {
      id: user.id,
      name: user.name,
      birthday: user.birthday,
      user_type: user.user_type
    }
  end

  def event_serializer(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      event_type: event.type,
      place: event.place
    }
  end

  def best_record_serializer(best_record_data)
    style = best_record_data[:style]
    record = best_record_data[:record]
    
    {
      style_name: style.name_jp,
      time: record.time,
      formatted_time: format_swim_time(record.time),
      note: record.note
    }
  end
end
