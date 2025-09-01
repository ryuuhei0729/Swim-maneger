class UserAuth < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

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

  # JWT認証用のメソッド（Devise JWT標準実装）
  def generate_jwt
    Rails.logger.debug "UserAuth#generate_jwt開始: id=#{id}, email=#{email}"
    
    begin
      # Devise JWTを使用してトークンを生成
      token = Warden::JWTAuth::UserEncoder.new.call(self, :user_auth, nil).first
      Rails.logger.debug "JWTトークン生成成功: #{token[0..20]}..."
      token
    rescue => e
      Rails.logger.error "UserAuth#generate_jwtエラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def revoke_jwt(authorization_header)
    return unless authorization_header.present?
    
    token = authorization_header.gsub('Bearer ', '')
    Rails.logger.debug "JWT無効化開始: #{token[0..20]}..."
    
    begin
      # Devise JWTを使用してトークンを無効化
      payload = Warden::JWTAuth::TokenDecoder.new.call(token)
      jti = payload['jti']
      exp = Time.at(payload['exp'])
      
      if jti && exp
        JwtDenylist.create!(jti: jti, exp: exp)
        Rails.logger.debug "JWT無効化成功: jti=#{jti}"
      end
    rescue => e
      Rails.logger.error "JWT無効化エラー: #{e.message}"
      # エラーが発生してもログアウトは成功とする
    end
  end

  # Devise JWTのコールバック用メソッド
  def jwt_payload
    # JWTペイロードに追加したいカスタム情報
    {
      user_id: user&.id,
      user_type: user&.user_type,
      generation: user&.generation
    }
  end

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
