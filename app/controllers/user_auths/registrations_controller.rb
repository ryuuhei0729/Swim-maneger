class UserAuths::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    session[:user_auth_id] = resource.id
    new_user_path
  end
end 