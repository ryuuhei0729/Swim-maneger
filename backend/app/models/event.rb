class Event < ApplicationRecord
  # STIを有効にする（typeカラムを使用）
  
  validates :title, presence: true
  validates :date, presence: true
  validates :type, presence: true
end
