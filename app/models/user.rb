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
  validates :gender, presence: true, inclusion: { in: [ "male", "female" ] }
  validates :birthday, presence: true
  validates :user_type, presence: true, inclusion: { in: [ "director", "coach", "player", "manager" ] }

  delegate :email, to: :user_auth, allow_nil: true

  # ユーザータイプの定数
  USER_TYPES = {
    player: "player",
    coach: "coach",
    director: "director",
    manager: "manager"
  }.freeze

  # 性別の定数
  GENDERS = {
    male: "male",
    female: "female"
  }.freeze

  # 管理者権限を持つユーザータイプ
  ADMIN_TYPES = [ USER_TYPES[:coach], USER_TYPES[:director], USER_TYPES[:manager] ].freeze

  # ユーザーが管理者かどうかを判定するメソッド
  def admin?
    ADMIN_TYPES.include?(user_type)
  end

  # ユーザータイプのバリデーション
  validates :user_type, inclusion: { in: USER_TYPES.values }
  # 性別のバリデーション
  validates :gender, inclusion: { in: GENDERS.values }

  # プロフィール画像のURLを取得するメソッド
  def profile_image_url
    avatar.attached? ? avatar : nil
  end

  def coach?
    user_type == "coach"
  end

  def player?
    user_type == "player"
  end
end
