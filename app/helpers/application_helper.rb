module ApplicationHelper
  # user_generationを出力するときに、単位をつけるメソッド（何期生）
  def ordinal_suffix(number)
    return "" if number.nil? || number.zero?
    if (11..13).include?(number % 100)
      "th"
    else
      case number % 10
      when 1 then "st"
      when 2 then "nd"
      when 3 then "rd"
      else "th"
      end
    end
  end

  # timeを出力するときに、形式を揃えるメソッド
  # 例）1:23.45
  def format_time(time)
    minutes = (time / 60).floor
    seconds = time % 60
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end

  # サークル時間を「分'秒"」の形式でフォーマットするメソッド
  # 例）90秒 → 1'30"
  def format_circle_time(seconds)
    return "0\"0" if seconds.nil? || seconds.zero?
    
    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round
    
    if minutes > 0
      "#{minutes}'#{remaining_seconds.to_s.rjust(2, '0')}\""
    else
      "#{remaining_seconds}\""
    end
  end

  # 日付の曜日を日本語で取得するメソッド
  def japanese_weekday(date)
    weekdays = { 'Sun' => '日', 'Mon' => '月', 'Tue' => '火', 'Wed' => '水', 'Thu' => '木', 'Fri' => '金', 'Sat' => '土' }
    weekdays[date.strftime('%a')]
  end

  # split timeをフォーマットするメソッド
  def format_split_time(time_in_seconds)
    return "" if time_in_seconds.blank?
    
    minutes = (time_in_seconds / 60).to_i
    seconds = (time_in_seconds % 60)
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end
end
