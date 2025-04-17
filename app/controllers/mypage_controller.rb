class MypageController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @best_time_table = @user.best_time_table || @user.create_best_time_table
  end

  def update
    @user = current_user_auth.user
    if @user.update(user_params)
      redirect_to mypage_path, notice: '自己紹介を更新しました'
    else
      redirect_to mypage_path, alert: '自己紹介の更新に失敗しました'
    end
  end

  private

  def user_params
    params.require(:user).permit(:bio)
  end
end
