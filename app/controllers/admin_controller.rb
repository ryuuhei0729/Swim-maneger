class AdminController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :check_admin_access

  def index
  end

  def create_user
    if request.post?
      @user = User.new(user_params)
      @user_auth = UserAuth.new(user_auth_params)
      
      User.transaction do
        if @user.save && @user_auth.save
          @user_auth.update(user: @user)
          redirect_to admin_path, notice: 'ユーザーを作成しました。'
        else
          if @user_auth.errors.any?
            @user_auth.errors.messages.each do |attribute, messages|
              messages.each do |message|
                if message.is_a?(Symbol)
                  translated_message = I18n.t("errors.messages.#{message}", default: I18n.t("activerecord.errors.messages.#{message}", default: message))
                  @user.errors.add(attribute, translated_message)
                else
                  @user.errors.add(attribute, message)
                end
              end
            end
          end
          render :create_user
        end
      end
    else
      @user = User.new
      @user_auth = UserAuth.new
    end
  end

  def announcement
    @announcements = Announcement.all.order(published_at: :desc)
    @announcement = Announcement.new
  end

  def create_announcement
    @announcement = Announcement.new(announcement_params)
    
    if @announcement.save
      redirect_to admin_announcement_path, notice: 'お知らせを作成しました。'
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :announcement
    end
  end

  def update_announcement
    @announcement = Announcement.find(params[:id])
    
    if @announcement.update(announcement_params)
      redirect_to admin_announcement_path, notice: 'お知らせを更新しました。'
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :announcement
    end
  end

  def destroy_announcement
    Rails.logger.info "destroy_announcement called with id: #{params[:id]}"
    @announcement = Announcement.find(params[:id])
    @announcement.destroy
    
    redirect_to admin_announcement_path, notice: 'お知らせを削除しました。'
  end

  def schedule
    @events = AttendanceEvent.order(date: :asc)
    @event = AttendanceEvent.new
  end

  def create_schedule
    @event = AttendanceEvent.new(schedule_params)
    if @event.save
      redirect_to admin_schedule_path, notice: 'スケジュールを登録しました。'
    else
      @events = AttendanceEvent.order(date: :asc)
      render :schedule
    end
  end

  def destroy_schedule
    @event = AttendanceEvent.find(params[:id])
    @event.destroy
    redirect_to admin_schedule_path, notice: 'スケジュールを削除しました。'
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
    if params[:user_auth].present?
      params.require(:user_auth).permit(:email, :password, :password_confirmation)
    else
      # フォームからuser_authパラメータが送信されていない場合、userパラメータから取得
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :is_active, :published_at)
  end

  def schedule_params
    params.require(:attendance_event).permit(:title, :date, :place, :note)
  end
end
