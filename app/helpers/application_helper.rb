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
end
