class UsersController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :set_user, only: [:edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = current_user_auth.build_user(user_params)
    if @user.save
      redirect_to root_path, notice: 'プロフィールが作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to mypage_path, notice: 'プロフィールが更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
    redirect_to root_path unless @user
  end

  def user_params
    params.require(:user).permit(:name, :generation, :gender, :birthday, :profile_image_url, :bio)
  end
end
