# frozen_string_literal: true

class UserAuths::SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [ :create ]

  def create
    super do |resource|
      if resource.persisted?
        flash[:needs_reload] = true
      end
    end
  end

  protected

  def after_sign_in_path_for(resource)
    home_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_auth_session_path
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [ :remember_me ])
  end
end
