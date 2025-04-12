class BestTimeTable < ApplicationRecord
  belongs_to :user

  # タイムのフォーマットを検証
  validate :validate_time_format

  private

  def validate_time_format
    time_columns = attributes.keys.select { |key| key.end_with?('_fr', '_br', '_ba', '_fly', '_im') && !key.end_with?('_note') }
    
    time_columns.each do |column|
      time = send(column)
      next if time.blank?
      
      # デフォルト値の場合はスキップ
      next if time == '00.00' || time == '0:00.00' || time == '00:00.00'
      
      # 3種類のフォーマットをチェック
      unless time.match?(/^\d{2}\.\d{2}$/) || # 1分未満: 00.00
             time.match?(/^\d{1,2}:\d{2}\.\d{2}$/) || # 1分以上10分未満: 0:00.00
             time.match?(/^\d{2}:\d{2}\.\d{2}$/) # 10分以上: 00:00.00
        errors.add(column, 'は正しい形式で入力してください（1分未満: 00.00、1分以上10分未満: 0:00.00、10分以上: 00:00.00）')
      end
    end
  end
end 