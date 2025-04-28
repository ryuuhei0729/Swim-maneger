class Admin::SchedulesController < ApplicationController
  before_action :require_admin

  def index
    # スケジュール一覧を取得する処理を追加予定
  end

  private

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "このページにアクセスする権限がありません"
      redirect_to root_path
    end
  end
end 