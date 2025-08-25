class PracticeTime < ApplicationRecord
  belongs_to :user
  belongs_to :practice_log

  validates :user_id, presence: true
  validates :practice_log_id, presence: true
  validates :rep_number, :set_number, :time, presence: true
  validates :rep_number, :set_number, numericality: { greater_than: 0 }
  validates :time, numericality: { greater_than: 0 }

  # 同じ練習ログ内で同じユーザーの同じセット・本数の組み合わせは一意
  validates :rep_number, uniqueness: {
    scope: [ :practice_log_id, :user_id, :set_number ],
    message: "このセット・本数の組み合わせは既に存在します"
  }
end
