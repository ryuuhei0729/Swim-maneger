class UserAuth < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable

  belongs_to :user, optional: true

  # DB制約と整合するバリデーション
  validates :email, presence: true, uniqueness: true, 
            format: { with: URI::MailTo::EMAIL_REGEXP, message: 'の形式が正しくありません' },
            length: { maximum: 255 }
  
  validates :encrypted_password, presence: true
  validates :authentication_token, uniqueness: true, allow_nil: true

  # パスワードのカスタムバリデーション
  validate :password_complexity, if: :password_required?
  validate :password_length, if: :password_required?

  before_create :build_default_user
  before_create :generate_authentication_token

  # プロフィール画像のURLを返すメソッド
  def profile_image_url
    # ここでは仮の実装として、GravatarのURLを返す
    # 実際の実装では、Active StorageやS3などを使用することを推奨
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=200&d=identicon"
  end

  # API認証トークンを再生成
  def regenerate_authentication_token
    generate_authentication_token
    save!
  end

  private

  def generate_authentication_token
    loop do
      self.authentication_token = SecureRandom.urlsafe_base64(32)
      break unless UserAuth.exists?(authentication_token: authentication_token)
    end
  end

  def build_default_user
    return if user.present?
    build_user(
      generation: 1,  # デフォルト値
      name: email.split("@").first,  # メールアドレスの@より前の部分を名前として使用
      gender: :male,  # enum対応
      birthday: Date.today,  # デフォルト値
      user_type: :player  # enum対応
    )
  end

  def password_required?
    new_record? || password.present? || password_confirmation.present?
  end

  def password_complexity
    return if password.blank?
    
    unless password.match?(/\A(?=.*[a-zA-Z])(?=.*\d)/)
      errors.add(:password, 'は英数字を含む必要があります')
    end
  end

  def password_length
    return if password.blank?
    
    if password.length < 6
      errors.add(:password, 'は6文字以上である必要があります')
    elsif password.length > 128
      errors.add(:password, 'は128文字以下である必要があります')
    end
  end
end
