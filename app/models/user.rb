class User < ApplicationRecord
  has_one :user_auth, dependent: :destroy
  has_one :best_time_table, dependent: :destroy
  has_one_attached :avatar

  validates :generation, presence: true
  validates :name, presence: true
  validates :gender, presence: true
  validates :birthday, presence: true
  validates :user_type, presence: true

  delegate :email, to: :user_auth, allow_nil: true

  # ユーザータイプの定数
  USER_TYPES = {
    player: 'player',
    coach: 'coach',
    director: 'director'
  }.freeze

  # 管理者権限を持つユーザータイプ
  ADMIN_TYPES = [USER_TYPES[:coach], USER_TYPES[:director]].freeze

  # ユーザーが管理者かどうかを判定するメソッド
  def admin?
    ADMIN_TYPES.include?(user_type)
  end

  # ユーザータイプのバリデーション
  validates :user_type, inclusion: { in: USER_TYPES.values }

  # プロフィール画像のURLを取得するメソッド
  def profile_image_url
    avatar.attached? ? avatar : nil
  end
end
