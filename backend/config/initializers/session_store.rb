# セッションストアの設定
Rails.application.config.session_store :active_record_store,
  key: "_swim_manager_session",
  expire_after: 30.minutes,  # クッキーオーバーフロー対策として短めに設定
  secure: Rails.env.production?,
  httponly: true,  # JavaScriptからアクセス不可
  same_site: :lax
