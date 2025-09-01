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
      
      # トークンのjti値を抽出してログに出力（トークン文字列は出力しない）
      jti = extract_jti_from_token(token)
      if jti
        Rails.logger.debug "JWTトークン生成成功: jti=#{jti}"
      else
        Rails.logger.debug "JWTトークン生成成功: jti抽出失敗"
      end
      
      token
    rescue => e
      Rails.logger.error "UserAuth#generate_jwtエラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def revoke_jwt(authorization_header)
    return unless authorization_header.present?
    
    # Bearerプレフィックスを除去
    token = authorization_header.gsub(/^Bearer\s+/, '')
    
    # トークンのjti値を抽出してログに出力（トークン文字列は出力しない）
    jti = extract_jti_from_token(token)
    if jti
      Rails.logger.debug "JWT無効化開始: jti=#{jti}"
    else
      Rails.logger.debug "JWT無効化開始: jti抽出失敗"
    end
    
    begin
      # Devise JWTを使用してトークンをデコード
      payload = Warden::JWTAuth::TokenDecoder.new.call(token)
      jti = payload['jti']
      exp = payload['exp']
      
      if jti.present? && exp.present?
        # 有効期限をTimeオブジェクトに変換
        expiration_time = Time.at(exp)
        
        # 既にdenylistに存在するかチェック
        unless JwtDenylist.exists?(jti: jti)
          JwtDenylist.create!(jti: jti, exp: expiration_time)
          Rails.logger.debug "JWT無効化成功: jti=#{jti}, exp=#{expiration_time}"
        else
          Rails.logger.debug "JWTは既に無効化済み: jti=#{jti}"
        end
      else
        Rails.logger.warn "JWTペイロードにjtiまたはexpが含まれていません: jti=#{jti}, exp=#{exp}"
      end
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWTデコードエラー（無効化スキップ）: #{e.message}"
      # JWTデコードエラーが発生した場合は警告ログを出力
    rescue => e
      Rails.logger.error "JWT無効化エラー: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      # その他のエラーが発生した場合はエラーログを出力
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

  # JWTトークンからjti値を安全に抽出するメソッド
  def extract_jti_from_token(token)
    return nil unless token.present?
    
    begin
      # JWTトークンをデコードしてjti値を抽出（署名検証なし）
      # 注意: 署名検証なしでデコードするため、セキュリティ上の問題はない
      payload = JWT.decode(token, nil, false, { verify_signature: false }).first
      payload['jti']
    rescue JWT::DecodeError => e
      Rails.logger.debug "JWTデコードエラー（jti抽出失敗）: #{e.message}"
      nil
    rescue => e
      Rails.logger.debug "JWT処理エラー（jti抽出失敗）: #{e.message}"
      nil
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
