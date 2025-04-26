class AttendanceController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @current_month = if params[:month].present?
      Date.parse(params[:month])
    else
      Date.current
    end

    @events_by_date = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
      .group_by { |event| event.date }

    respond_to do |format|
      format.html
      format.js { 
        render partial: 'shared/calendar', locals: { 
          current_month: @current_month,
          events_by_date: @events_by_date
        }
      }
    end
  end
end 