module ApplicationHelper
  def ordinal_suffix(number)
    return "" if number.nil?
    
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
end 