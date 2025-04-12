class ApplicationController < ActionController::Base
  before_action :authenticate_user_auth!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
  end

  def after_sign_in_path_for(resource)
    home_path
  end

  def after_sign_out_path_for(resource)
    new_user_auth_session_path
  end
end
