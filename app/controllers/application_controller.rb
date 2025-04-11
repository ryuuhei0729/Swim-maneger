class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user_auth!

  def current_user
    current_user_auth&.user
  end
  helper_method :current_user
end
