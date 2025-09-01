class ApplicationController < ActionController::Base
  before_action :authenticate_user_auth!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # APIコントローラーではDeviseの認証をスキップ
  skip_before_action :authenticate_user_auth!, if: :api_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
  end

  def after_sign_in_path_for(_resource)
    home_path
  end

  def after_sign_out_path_for(_resource)
    new_user_auth_session_path
  end

  # エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity

  private

  def render_not_found(exception)
    render file: "#{Rails.root}/app/views/errors/not_found.html.erb", status: :not_found, layout: "error"
  end

  def render_unprocessable_entity(exception)
    render file: "#{Rails.root}/app/views/errors/unprocessable_entity.html.erb", status: :unprocessable_entity, layout: "error"
  end

  # TODO: Deviseメソッドとの競合を避けるため、将来的にメソッド名を変更することを検討
  # 例: authenticate_api_user! → authenticate_api_user_auth!

  # JSONレスポンス用ヘルパーメソッド（API標準形式）
  def render_success(data = {}, message = nil, status = :ok, code: nil)
    payload = { success: true }
    payload[:data] = data unless data.empty?
    payload[:message] = message if message.present?
    payload[:code] = code if code.present?
    render json: payload, status: status
  end

  def render_error(message, status = :bad_request, errors = {}, code: nil)
    payload = {
      success: false,
      message: message
    }
    payload[:errors] = errors unless errors.empty?
    payload[:code] = code if code.present?
    render json: payload, status: status
  end

  private

  def api_controller?
    controller_path.start_with?('api/')
  end
end
