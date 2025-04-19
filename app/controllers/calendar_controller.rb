class CalendarController < ApplicationController
  def update
    params_json = JSON.parse(request.body.read)
    @current_month = Date.new(params_json["year"].to_i, params_json["month"].to_i, 1)
    @events_by_date = AttendanceEvent.where(date: @current_month.all_month).group_by { |event| event.date }
    
    respond_to do |format|
      format.html { render partial: 'shared/calendar' }
    end
  end
end 