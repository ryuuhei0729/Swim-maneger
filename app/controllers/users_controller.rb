class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.user_type = 'member'  # デフォルト値を設定
    @user.user_auth = UserAuth.find(session[:user_auth_id])

    if @user.save
      session.delete(:user_auth_id)
      redirect_to root_path, notice: 'プロフィールの登録が完了しました'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :generation, :gender, :birthday, :profile_image_url, :bio)
  end
end
