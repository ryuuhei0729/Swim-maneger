class AdminController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :check_admin_access

  def index
  end

  def create_user
    if request.post?
      @user = User.new(user_params)
      @user_auth = UserAuth.new(user_auth_params)
      
      if @user.save && @user_auth.save
        redirect_to admin_path, notice: 'ユーザーを作成しました。'
      else
        @user.errors.merge!(@user_auth.errors) if @user_auth.errors.any?
        render :create_user
      end
    else
      @user = User.new
      @user_auth = UserAuth.new
    end
  end

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?(['coach', 'director'])
      redirect_to root_path, alert: 'このページにアクセスする権限がありません。'
    end
  end

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday)
  end

  def user_auth_params
    params.require(:user).permit(:email, :password, :password_confirmation).merge(user: @user)
  end
end
