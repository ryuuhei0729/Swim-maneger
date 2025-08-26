module DateParser
  extend ActiveSupport::Concern

  private

  def parse_date(value)
    return nil if value.blank?
    
    case value
    when Date, DateTime
      value.to_date
    when String
      begin
        Date.parse(value)
      rescue ArgumentError
        nil
      end
    when Numeric
      # Excelの日付シリアル値の場合
      begin
        Date.new(1900, 1, 1) + value.to_i - 2
      rescue
        nil
      end
    else
      nil
    end
  end
end
