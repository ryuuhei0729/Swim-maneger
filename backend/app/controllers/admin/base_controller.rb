class Admin::BaseController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :check_admin_access

  def index
    # 管理画面のダッシュボード
  end

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?(["coach", "director", "manager"])
      redirect_to home_path, alert: "このページにアクセスする権限がありません。"
    end
  end

  # セキュアな暗号化・復号化メソッド（インポート機能で使用）
  def encrypt_preview_data(data)
    encryptor = ActiveSupport::MessageEncryptor.new(encryption_key)
    encryptor.encrypt_and_sign(data)
  end

  def decrypt_preview_data(encrypted_data)
    encryptor = ActiveSupport::MessageEncryptor.new(encryption_key)
    encryptor.decrypt_and_verify(encrypted_data)
  end

  def encryption_key
    # ActiveSupport::KeyGeneratorを使用してセキュアなキーを生成
    # 安定したソルト文字列を使用して一貫性を保つ
    salt = "jwt encryption"
    
    # Rails.application.credentials.secret_key_baseからキーを生成
    # MessageEncryptor.key_lenに一致する長さのキーを生成
    key_generator = ActiveSupport::KeyGenerator.new(
      Rails.application.credentials.secret_key_base
    )
    
    # 32バイト（256ビット）のキーを生成
    key_generator.generate_key(salt, ActiveSupport::MessageEncryptor.key_len)
  end
end 