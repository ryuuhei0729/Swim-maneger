class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @current_month = Date.current
    @events_by_date = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
      .group_by { |event| event.date }
    
    @announcements = Announcement.active.where("published_at <= ?", Time.current).order(published_at: :desc)
    
    # 今日が誕生日のユーザーを取得
    today = Date.current
    @birthday_users = User.where("EXTRACT(MONTH FROM birthday) = ? AND EXTRACT(DAY FROM birthday) = ?", today.month, today.day)
  end
end
