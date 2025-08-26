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
      type: event.type,
      place: event.place
    }
  end

  def best_record_serializer(best_record_data)
    style = best_record_data[:style]
    record = best_record_data[:record]
    
    {
      style_name: style.name_jp,
      time: record.time,
      formatted_time: record.formatted_time,
      note: record.note
    }
  end
end
