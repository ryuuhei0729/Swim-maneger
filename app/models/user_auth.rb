class UserAuth < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :user, optional: true

  before_create :build_default_user

  private

  def build_default_user
    return if user.present?
    build_user(
      generation: 1,  # デフォルト値
      name: email.split('@').first,  # メールアドレスの@より前の部分を名前として使用
      gender: 'male',  # デフォルト値
      birthday: Date.today,  # デフォルト値
      user_type: 'member'  # デフォルト値
    )
  end
end 