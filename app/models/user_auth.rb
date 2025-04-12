class UserAuth < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :user, optional: true

  before_create :build_default_user

  # プロフィール画像のURLを返すメソッド
  def profile_image_url
    # ここでは仮の実装として、GravatarのURLを返す
    # 実際の実装では、Active StorageやS3などを使用することを推奨
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=200&d=identicon"
  end

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