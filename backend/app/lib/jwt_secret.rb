# frozen_string_literal: true

# JWT秘密鍵の一元管理クラス
# 全てのJWT関連の秘密鍵取得を統一的に処理
class JwtSecret
  class << self
    # 基本的なJWT秘密鍵を取得
    # 優先順位: ENV['JWT_SECRET_KEY'] > credentials.jwt_secret_key > secret_key_base (非本番環境のみ)
    # 本番環境ではjwt_secret_keyの設定を必須とする
    # @return [String] JWT秘密鍵
    def key
      @key ||= begin
        # 環境変数JWT_SECRET_KEYが設定されている場合はそれを使用
        if ENV['JWT_SECRET_KEY'].present?
          ENV['JWT_SECRET_KEY']
        # credentials.jwt_secret_keyが設定されている場合はそれを使用
        elsif Rails.application.credentials.jwt_secret_key.present?
          Rails.application.credentials.jwt_secret_key
        # 本番環境ではjwt_secret_keyの設定を必須とする
        elsif Rails.env.production?
          error_msg = "本番環境ではJWT_SECRET_KEY環境変数またはcredentials.jwt_secret_keyの設定が必要です"
          Rails.logger.error "JWT秘密鍵設定エラー: #{error_msg}"
          raise error_msg
        # 非本番環境ではsecret_key_baseにフォールバック（警告付き）
        else
          Rails.logger.warn "JWT秘密鍵: jwt_secret_keyが設定されていないため、secret_key_baseにフォールバックします"
          Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
        end
      end
    end

    # 固定長（32バイト）の秘密鍵を取得
    # 暗号化処理など、固定長が必要な場合に使用
    # @param [Integer] length 必要なバイト数（デフォルト: 32）
    # @return [String] 固定長の秘密鍵
    def fixed_length_key(length = 32)
      base_key = key
      if base_key.length >= length
        base_key[0, length]
      else
        # 短い場合はハッシュ化して長さを確保
        Digest::SHA256.hexdigest(base_key)[0, length]
      end
    end

    # テスト環境用の秘密鍵を取得
    # テスト環境では固定値を使用してテストの一貫性を保つ
    # @return [String] テスト用秘密鍵
    def test_key
      Rails.env.test? ? 'test-secret-key-for-jwt-authentication' : key
    end

    # テスト環境用のJWT有効期限を取得
    # テスト環境では短い有効期限を使用してテストの高速化を図る
    # @return [Integer] JWT有効期限（秒）
    def test_expiration_time
      Rails.env.test? ? 5.minutes.to_i : 1.hour.to_i
    end

    # キャッシュをクリア（主にテスト用）
    def clear_cache!
      @key = nil
    end
  end
end
