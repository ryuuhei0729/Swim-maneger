class MypageController < ApplicationController
  before_action :authenticate_user_auth!

  def show
    @user = current_user
  end
end
