class HomeController < ApplicationController
  before_action :authenticate_user_auth!
  def index
  end
end
