class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @announcements = Announcement.active.where("published_at <= ?", Time.current).order(published_at: :desc)
  end
end
