class MypageController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @best_time_table = @user.best_time_table || @user.create_best_time_table
  end
end
