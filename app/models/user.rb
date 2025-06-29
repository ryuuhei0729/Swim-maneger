class User < ApplicationRecord
  has_one :user_auth, dependent: :destroy
  has_one_attached :avatar
  has_many :attendance, dependent: :destroy
  has_many :attendance_events, through: :attendance
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy
  has_many :race_feedbacks, dependent: :destroy

  validates :generation, presence: true
  validates :name, presence: true
  validates :birthday, presence: true
  validates :user_type, presence: true
  validates :gender, presence: true

  delegate :email, to: :user_auth, allow_nil: true

  # enum宣言（Rails 8.0対応）
  enum :user_type, {
    player: 0,
    manager: 1,
    coach: 2,
    director: 3
  }

  enum :gender, {
    male: 0,
    female: 1,
    other: 2
  }

  # 管理者権限を持つユーザータイプ（enum対応）
  ADMIN_USER_TYPES = %w[coach director manager].freeze

  # ユーザーが管理者かどうかを判定するメソッド
  def admin?
    ADMIN_USER_TYPES.include?(user_type)
  end

  # プロフィール画像のURLを取得するメソッド
  def profile_image_url
    avatar.attached? ? avatar : nil
  end

  def best_time_notes
    best_notes = {}
    Style.all.each do |style|
      best_record = records.where(style: style).order(:time).first
      best_notes[style.name] = best_record&.note
    end
    best_notes
  end
end
