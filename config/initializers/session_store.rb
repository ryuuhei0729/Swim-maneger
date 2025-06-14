# セッションストアの設定
Rails.application.config.session_store :cookie_store,
  key: "_swim_manager_session",
  expire_after: 24.hours,
  secure: Rails.env.production?,
  same_site: :lax
