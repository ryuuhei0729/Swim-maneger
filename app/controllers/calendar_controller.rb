class CalendarController < ApplicationController
  # カレンダーのデータを更新するためのメソッド
  # params[:year]とparams[:month]を受け取って、その月のAttendanceEventを取得する
  # 取得したAttendanceEventを日付ごとにグループ化して@events_by_dateに格納する
  # 最後に、部分テンプレート'_calendar.html.erb'をrenderする
  def update
    params_json = JSON.parse(request.body.read)
    @current_month = Date.new(params_json["year"].to_i, params_json["month"].to_i, 1)
    
    attendance_events = AttendanceEvent.where(date: @current_month.all_month).order(date: :asc)
    events = Event.where(date: @current_month.all_month).order(date: :asc)
    
    # 両方のイベントを日付ごとにグループ化してマージ
    @events_by_date = {}
    
    # Eventを先に追加（上に表示される）
    events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end
    
    # AttendanceEventを後から追加（下に表示される）
    attendance_events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end

    respond_to do |format|
      format.html { render partial: "shared/calendar" }
    end
  end
end
