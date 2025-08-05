class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_user_auth!

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
          render_error('Validation failed', :unprocessable_content, e.record.errors.as_json)
  end
end 