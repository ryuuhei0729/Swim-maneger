class Event < ApplicationRecord
  # STIを無効化してtypeカラムを通常のカラムとして扱う
  self.inheritance_column = :_type_disabled
  
  validates :title, presence: true
  validates :date, presence: true
  validates :type, presence: true
end
