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
    # 本番環境では環境変数から取得することを推奨
    JwtSecret.fixed_length_key(32)
  end
end 