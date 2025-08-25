class Api::V1::RacesController < Api::V1::BaseController
  def index
    practice_logs = PracticeLog.includes(:practice_times, :attendance_event)
                              .where(practice_times: { user_id: current_user_auth.user.id })
                              .order(created_at: :desc)

    render_success({
      total_count: practice_logs.count,
      practice_logs: practice_logs.map { |log| format_practice_log(log) }
    })
  end

  def show
    practice_log = PracticeLog.find(params[:id])
    practice_times = practice_log.practice_times.where(user_id: current_user_auth.user.id)
                                               .order(set_number: :asc, rep_number: :asc)

    # 他のユーザーのタイムが含まれていないかチェック
    if practice_times.empty?
      render_error("この練習記録にはあなたのタイムが記録されていません", :not_found)
      return
    end

    render_success({
      practice_log: format_practice_log_detail(practice_log),
      practice_times: format_practice_times(practice_times)
    })
  end

  private

  def format_practice_log(log)
    {
      id: log.id,
      date: log.attendance_event.date,
      event_title: log.attendance_event.title,
      style: log.style,
      style_name: PracticeLog::STYLE_OPTIONS[log.style],
      distance: log.distance,
      rep_count: log.rep_count,
      set_count: log.set_count,
      circle: log.circle,
      note: log.note,
      created_at: log.created_at,
      times_count: log.practice_times.where(user_id: current_user_auth.user.id).count
    }
  end

  def format_practice_log_detail(log)
    {
      id: log.id,
      date: log.attendance_event.date,
      event_title: log.attendance_event.title,
      event_place: log.attendance_event.place,
      style: log.style,
      style_name: PracticeLog::STYLE_OPTIONS[log.style],
      distance: log.distance,
      rep_count: log.rep_count,
      set_count: log.set_count,
      circle: log.circle,
      note: log.note,
      created_at: log.created_at
    }
  end

  def format_practice_times(practice_times)
    # セット別にグループ化
    grouped_by_set = practice_times.group_by(&:set_number)
    
    sets = grouped_by_set.map do |set_number, times|
      {
        set_number: set_number,
        reps: times.map { |time| format_practice_time(time) },
        average_time: calculate_average_time(times),
        best_time: times.map(&:time).min
      }
    end

    {
      sets: sets,
      total_times: practice_times.count,
      overall_best: practice_times.map(&:time).min,
      overall_average: calculate_average_time(practice_times)
    }
  end

  def format_practice_time(practice_time)
    {
      rep_number: practice_time.rep_number,
      time: practice_time.time,
      formatted_time: format_time_display(practice_time.time)
    }
  end

  def calculate_average_time(times)
    return 0.0 if times.empty?
    times.sum(&:time) / times.count.to_f
  end

  def format_time_display(seconds)
    return "-" if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round(2)

    if minutes.zero?
      sprintf("%05.2f", remaining_seconds)
    else
      sprintf("%d:%05.2f", minutes, remaining_seconds)
    end
  end
end 