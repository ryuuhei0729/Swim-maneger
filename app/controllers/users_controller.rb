class UsersController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :set_user, only: [:show, :edit, :update]
  helper_method :resource_name, :resource, :devise_mapping

  def index
    @users = User.all
  end

  def show
  end

  def create
    @user = User.new
  end

  def update
    @user = User.new(user_params)
    @user.user_type = 'member' # デフォルトでmemberを設定
    @user.user_auth = current_user_auth

    if @user.save
      redirect_to @user, notice: 'ユーザーが正常に作成されました。'
    else
      render :create, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'ユーザーが正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :generation, :gender, :birthday, :profile_image_url, :bio)
  end

  def resource_name
    :user_auth
  end

  def resource
    @resource ||= UserAuth.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user_auth]
  end
end
