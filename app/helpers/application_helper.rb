module ApplicationHelper
  def ordinal_suffix(number)
    return 'th' if [11, 12, 13].include?(number % 100)
    
    case number % 10
    when 1 then 'st'
    when 2 then 'nd'
    when 3 then 'rd'
    else 'th'
    end
  end
end
