require_relative "boot"

require "rails/all"
require "holiday_jp"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SwimManager
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local

    # Rails 8.1の非推奨警告を解決
    config.active_support.to_time_preserves_timezone = :zone

    # エラーページの設定
    config.exceptions_app = self.routes

    # デフォルトのロケールを日本語に設定
    config.i18n.default_locale = :ja
    config.i18n.available_locales = [ :ja, :en ]

    # libディレクトリを自動ロードパスに追加
    config.autoload_paths << Rails.root.join("app/lib")
  end
end
