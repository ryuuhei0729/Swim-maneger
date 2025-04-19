class ApplicationController < ActionController::Base
  before_action :authenticate_user_auth!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    home_path
  end

  def after_sign_out_path_for(resource)
    new_user_auth_session_path
  end

  # エラーハンドリング
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_unprocessable_entity

  private

  def render_not_found(exception)
    render file: "#{Rails.root}/app/views/errors/not_found.html.erb", status: :not_found, layout: 'error'
  end

  def render_unprocessable_entity(exception)
    render file: "#{Rails.root}/app/views/errors/unprocessable_entity.html.erb", status: :unprocessable_entity, layout: 'error'
  end
end
