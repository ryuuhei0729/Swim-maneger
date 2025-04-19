class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @current_month = Date.current
    @events_by_date = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
      .group_by { |event| event.date }
    
    @announcements = Announcement.active.where("published_at <= ?", Time.current).order(published_at: :desc)
  end
end
