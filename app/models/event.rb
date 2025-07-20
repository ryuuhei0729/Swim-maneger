class Event < ApplicationRecord
  # 一時的にnew_eventsテーブルを使用（後でリネーム予定）
  self.table_name = 'new_events'
  
  validates :title, presence: true
  validates :date, presence: true
  validates :type, presence: true
end
