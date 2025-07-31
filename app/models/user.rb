class User < ApplicationRecord
  has_one :user_auth, dependent: :destroy
  has_one_attached :avatar
  has_many :attendance, dependent: :destroy
  has_many :attendance_events, through: :attendance
  has_many :records, dependent: :destroy
  has_many :objectives, dependent: :destroy
  has_many :race_goals, dependent: :destroy
  has_many :race_feedbacks, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :practice_times, dependent: :destroy

  # 必須項目のバリデーション（DB制約と整合）
  validates :generation, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 1000 }
  validates :name, presence: true, length: { maximum: 255 }
  validates :user_type, presence: true
  validates :gender, presence: true

  # 日付のバリデーション
  validates :birthday, presence: false, allow_nil: true
  validate :birthday_cannot_be_in_future
  validate :birthday_cannot_be_too_old

  # 文字列のバリデーション
  validates :bio, length: { maximum: 1000 }, allow_nil: true

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

  private

  def birthday_cannot_be_in_future
    if birthday.present? && birthday > Date.current
      errors.add(:birthday, 'は未来の日付にできません')
    end
  end

  def birthday_cannot_be_too_old
    if birthday.present? && birthday < Date.new(1900, 1, 1)
      errors.add(:birthday, 'は1900年以降の日付にしてください')
    end
  end
end
