class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = 'jwt_denylists'

  # バリデーション
  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  # 有効期限が切れたレコードを自動削除
  scope :expired, -> { where('exp < ?', Time.current) }
  
  # 定期的に古いレコードをクリーンアップ
  def self.cleanup_expired
    expired.delete_all
  end
end
