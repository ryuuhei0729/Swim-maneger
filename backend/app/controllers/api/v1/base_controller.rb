class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include SanitizationHelper

  before_action :authenticate_user_auth!
  before_action :set_security_headers

  protected

  def authenticate_user_auth!
    authenticate_with_http_token do |token, _options|
      @current_user_auth = UserAuth.find_by(authentication_token: token)
    end

    unless @current_user_auth
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def current_user_auth
    @current_user_auth
  end

  def render_success(data = {}, message = nil, status = :ok)
    response = { success: true }
    response[:message] = message if message
    response[:data] = data unless data.empty?
    render json: response, status: status
  end

  def render_error(message, status = :bad_request, errors = {})
    response = { 
      success: false, 
      message: message 
    }
    response[:errors] = errors unless errors.empty?
    render json: response, status: status
  end

  # エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error('Record not found', :not_found)
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error("Missing parameter: #{e.param}", :bad_request)
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render_error('Validation failed', :unprocessable_entity, e.record.errors.as_json)
  end

  # セキュリティヘッダーの設定
  def set_security_headers
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
  end

  # 管理者権限チェック
  def require_admin!
    unless current_user_auth&.user&.admin?
      render_error('管理者権限が必要です', :forbidden)
      return
    end
  end

  # パラメータのサニタイゼーション
  def sanitize_params(params)
    params.each do |key, value|
      if value.is_a?(String)
        sanitized = sanitize_html(value)
        # 空文字列の意味を保持
        params[key] = sanitized.nil? && value == "" ? "" : sanitized
      elsif value.is_a?(Hash)
        params[key] = sanitize_params(value)
      elsif value.is_a?(Array)
        params[key] = value.map do |element|
          if element.is_a?(String)
            sanitized = sanitize_html(element)
            # 空文字列の意味を保持
            sanitized.nil? && element == "" ? "" : sanitized
          elsif element.is_a?(Hash)
            sanitize_params(element)
          else
            element
          end
        end
      end
    end
    params
  end

  # ログ出力の強化
  def log_api_request(action, params = {})
    Rails.logger.info({
      timestamp: Time.current,
      user_id: current_user_auth&.user&.id,
      action: action,
      params: request.filtered_parameters,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    }.to_json)
  end
end 