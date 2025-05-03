class BestTimeTable < ApplicationRecord
  belongs_to :user

  # タイムのフォーマットを検証
  validate :validate_time_format

  # タイムを表示用の文字列にフォーマット
  def format_time(column)
    time = send(column)
    return "-" if time.blank?

    # 文字列の場合は数値に変換
    time = time.to_f if time.is_a?(String)
    return "-" if time.zero?

    minutes = (time / 60).floor
    remaining_seconds = (time % 60).round(2)
    
    if minutes.zero?
      format("%05.2f", remaining_seconds)
    else
      format("%d:%05.2f", minutes, remaining_seconds)
    end
  end

  private

  def validate_time_format
    time_columns = attributes.keys.select { |key| key.end_with?('_fr', '_br', '_ba', '_fly', '_im') && !key.end_with?('_note') }
    
    time_columns.each do |column|
      time = send(column)
      next if time.blank?
      
      # 文字列の場合は数値に変換
      time = time.to_f if time.is_a?(String)
      
      # 数値型の値が正の数であることを確認
      unless time.is_a?(Numeric) && time >= 0
        errors.add(column, 'は正の数で入力してください')
      end
    end
  end
end 