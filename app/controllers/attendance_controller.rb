class AttendanceController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    # 後で機能を追加するため、現時点では空のメソッド
  end
end 