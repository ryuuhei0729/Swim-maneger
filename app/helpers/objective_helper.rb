module ObjectiveHelper
  def format_time(seconds)
    return "-" if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round(2)

    if minutes.zero?
      format("%05.2f", remaining_seconds)
    else
      format("%d:%05.2f", minutes, remaining_seconds)
    end
  end

  def days_until(date)
    (date.to_date - Date.current).to_i
  end

  def format_days_until(date)
    days = days_until(date)
    "#{days}"
  end
end
