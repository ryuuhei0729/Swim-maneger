class User < ApplicationRecord
  has_one :user_auth, dependent: :destroy

  validates :generation, presence: true
  validates :name, presence: true
  validates :gender, presence: true
  validates :birthday, presence: true
  validates :user_type, presence: true

  delegate :email, to: :user_auth, allow_nil: true
end
