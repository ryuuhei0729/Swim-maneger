class CalendarController < ApplicationController
  def update
    params_json = JSON.parse(request.body.read)
    @current_month = Date.new(params_json["year"].to_i, params_json["month"].to_i, 1)
    @events_by_date = AttendanceEvent.where(date: @current_month.all_month).group_by { |event| event.date }
    
    # デバッグログを追加
    Rails.logger.debug "=== Calendar Update Debug ==="
    Rails.logger.debug "Request params: #{params_json.inspect}"
    Rails.logger.debug "@current_month: #{@current_month.inspect}"
    Rails.logger.debug "@events_by_date: #{@events_by_date.inspect}"
    
    respond_to do |format|
      format.html { render partial: 'shared/calendar' }
    end
  end
end 