module TimeHelper
  # 時間文字列を秒数に変換するヘルパーメソッド
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

  # 時間フォーマット関連のヘルパーメソッド
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

  def format_time_display(seconds)
    format_time(seconds)
  end

  def format_swim_time(seconds)
    format_time(seconds)
  end

  # サークルタイム（目標タイム）のフォーマット
  def format_circle_time(seconds)
    return "-" unless seconds&.positive?
    
    if seconds >= 60
      minutes = seconds / 60
      remaining_seconds = seconds % 60
      "#{minutes.to_i}:#{sprintf('%02d', remaining_seconds.to_i)}"
    else
      "#{seconds.to_i}秒"
    end
  end

  # 年齢計算
  def calculate_age(birthday)
    return nil unless birthday
    
    today = Date.current
    age = today.year - birthday.year
    # 誕生日がまだ来ていない場合は1を引く
    age -= 1 if today.month < birthday.month || (today.month == birthday.month && today.day < birthday.day)
    age
  end
end
