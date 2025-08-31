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

  # パスワードのカスタムバリデーション
  validate :password_complexity, if: :password_required?
  validate :password_length, if: :password_required?

  before_create :build_default_user

  # プロフィール画像のURLを返すメソッド
  def profile_image_url
    # ここでは仮の実装として、GravatarのURLを返す
    # 実際の実装では、Active StorageやS3などを使用することを推奨
    "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.downcase)}?s=200&d=identicon"
  end



  # JWTトークンを生成
  def generate_jwt
    JWT.encode(
      {
        user_id: id,
        email: email,
        exp: 24.hours.from_now.to_i
      },
      ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base,
      'HS256'
    )
  end

  # JWTトークンを無効化
  def revoke_jwt(authorization_header)
    return unless authorization_header.present?
    
    token = authorization_header.gsub('Bearer ', '')
    begin
      # JWTトークンを検証してペイロードを取得
      decoded_token = JWT.decode(
        token,
        ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base,
        true,
        { algorithm: 'HS256' }
      )
      
      # 無効化されたトークンのリストに追加（Redis等を使用）
      # 実際の実装では、Redisやデータベースに無効化されたトークンを保存
      Rails.logger.info "JWTトークンを無効化: #{token[0..10]}..."
      
    rescue JWT::DecodeError => e
      Rails.logger.warn "無効なJWTトークン: #{e.message}"
    end
  end

  # JWTトークンからユーザーを取得
  def self.from_jwt_token(token)
    begin
      decoded_token = JWT.decode(
        token,
        ENV['JWT_SECRET_KEY'] || Rails.application.secret_key_base,
        true,
        { algorithm: 'HS256' }
      )
      
      user_id = decoded_token[0]['user_id']
      find_by(id: user_id)
      
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWTトークン検証エラー: #{e.message}"
      nil
    end
  end

  private



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
