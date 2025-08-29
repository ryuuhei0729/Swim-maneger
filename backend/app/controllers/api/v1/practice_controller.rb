class Api::V1::PracticeController < Api::V1::BaseController
  def index
    # 現在のユーザーが参加した練習記録を取得
    practice_log_ids = PracticeTime.where(user_id: current_user_auth.user.id)
                                   .distinct
                                   .pluck(:practice_log_id)
    
    practice_logs = PracticeLog.includes(:attendance_event, :practice_times)
                              .where(id: practice_log_ids)
                              .joins(:attendance_event)
                              .order("events.date DESC")

    # ページネーション対応
    page = params[:page]&.to_i || 1
    page = [page, 1].max # 最小1ページ
    per_page = params[:per_page]&.to_i || 20
    per_page = [per_page, 50].min # 最大50件まで

    total_count = practice_logs.count
    practice_logs = practice_logs.offset((page - 1) * per_page).limit(per_page)

    render_success({
      practice_logs: practice_logs.map { |log| format_practice_log_summary(log) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil,
        has_next: page * per_page < total_count,
        has_prev: page > 1
      },
      statistics: build_practice_statistics
    })
  end

  def practice_times
    practice_log = PracticeLog.includes(:attendance_event, practice_times: :user)
                             .find(params[:id])

    # 現在のユーザーのタイムのみ取得
    user_practice_times = practice_log.practice_times
                                    .where(user_id: current_user_auth.user.id)
                                    .order(set_number: :asc, rep_number: :asc)

    # ユーザーが参加していない練習記録の場合はエラー
    if user_practice_times.empty?
      render_error("この練習記録にはあなたのタイムが記録されていません", status: :not_found)
      return
    end

    render_success({
      practice_log: format_practice_log_detail(practice_log),
      practice_times: format_practice_times_detail(user_practice_times),
      analytics: build_practice_analytics(user_practice_times, practice_log)
    })
  end

  def show
    practice_log = PracticeLog.includes(:attendance_event, practice_times: :user)
                             .find(params[:id])

    # 現在のユーザーのタイムを確認
    user_practice_times = practice_log.practice_times
                                    .where(user_id: current_user_auth.user.id)

    if user_practice_times.empty?
      render_error("この練習記録にはあなたのタイムが記録されていません", status: :not_found)
      return
    end

    render_success({
      practice_log: format_practice_log_detail(practice_log),
      summary: build_practice_summary(user_practice_times, practice_log)
    })
  end

  private

  def format_practice_log_summary(log)
    user_times = log.practice_times.select { |pt| pt.user_id == current_user_auth.user.id }
    
    {
      id: log.id,
      date: log.attendance_event.date,
      formatted_date: log.attendance_event.date.strftime("%Y年%m月%d日"),
      event_title: log.attendance_event.title,
      event_place: log.attendance_event.place,
      style: log.style,
      style_name: PracticeLog::STYLE_OPTIONS[log.style],
      distance: log.distance,
      formatted_distance: "#{log.distance}m",
      rep_count: log.rep_count,
      set_count: log.set_count,
      circle: log.circle,
      formatted_circle: log.circle > 0 ? "#{log.circle}秒サークル" : "フリーペース",
      note: log.note,
      created_at: log.created_at,
      my_times_count: user_times.count,
      my_best_time: user_times.map(&:time).min&.to_f,
      my_average_time: user_times.any? ? (user_times.sum(&:time).to_f / user_times.count.to_f) : nil,
      formatted_best_time: format_swim_time(user_times.map(&:time).min),
      formatted_average_time: format_swim_time(user_times.any? ? (user_times.sum(&:time) / user_times.count.to_f) : nil)
    }
  end

  def format_practice_log_detail(log)
    {
      id: log.id,
      date: log.attendance_event.date,
      formatted_date: log.attendance_event.date.strftime("%Y年%m月%d日(%a)"),
      event_title: log.attendance_event.title,
      event_place: log.attendance_event.place,
      event_note: log.attendance_event.note,
      style: log.style,
      style_name: PracticeLog::STYLE_OPTIONS[log.style],
      distance: log.distance,
      formatted_distance: "#{log.distance}m",
      rep_count: log.rep_count,
      set_count: log.set_count,
      circle: log.circle,
      formatted_circle: log.circle > 0 ? "#{log.circle}秒サークル" : "フリーペース",
      note: log.note,
      created_at: log.created_at,
      total_distance: log.distance * log.rep_count * log.set_count,
      formatted_total_distance: "#{log.distance * log.rep_count * log.set_count}m"
    }
  end

  def format_practice_times_detail(practice_times)
    # セット別にグループ化
    grouped_by_set = practice_times.group_by(&:set_number)
    
    sets = grouped_by_set.map do |set_number, times|
      sorted_times = times.sort_by(&:rep_number)
      
      {
        set_number: set_number,
        reps: sorted_times.map { |time| format_practice_time(time) },
        set_stats: {
          total_reps: sorted_times.count,
          average_time: calculate_average_time(sorted_times)&.to_f,
          best_time: sorted_times.map(&:time).min&.to_f,
          worst_time: sorted_times.map(&:time).max&.to_f,
          formatted_average: format_swim_time(calculate_average_time(sorted_times)),
          formatted_best: format_swim_time(sorted_times.map(&:time).min),
          formatted_worst: format_swim_time(sorted_times.map(&:time).max),
          time_variance: calculate_time_variance(sorted_times)
        }
      }
    end

    {
      sets: sets.sort_by { |set| set[:set_number] },
      overall_stats: {
        total_times: practice_times.count,
        overall_best: practice_times.map(&:time).min&.to_f,
        overall_worst: practice_times.map(&:time).max&.to_f,
        overall_average: calculate_average_time(practice_times)&.to_f,
        formatted_best: format_swim_time(practice_times.map(&:time).min),
        formatted_worst: format_swim_time(practice_times.map(&:time).max),
        formatted_average: format_swim_time(calculate_average_time(practice_times)),
        consistency_score: calculate_consistency_score(practice_times)&.to_f
      }
    }
  end

  def format_practice_time(practice_time)
    {
      rep_number: practice_time.rep_number,
      time: practice_time.time,
      formatted_time: format_swim_time(practice_time.time)
    }
  end

  def build_practice_summary(user_practice_times, practice_log)
    times = user_practice_times.map(&:time)
    
    {
      participation_stats: {
        completed_reps: user_practice_times.count,
        expected_reps: practice_log.rep_count * practice_log.set_count,
        completion_rate: (user_practice_times.count.to_f / (practice_log.rep_count * practice_log.set_count) * 100).round(1)
      },
      time_stats: {
        best_time: times.min&.to_f,
        worst_time: times.max&.to_f,
        average_time: calculate_average_time(user_practice_times)&.to_f,
        formatted_best: format_swim_time(times.min),
        formatted_worst: format_swim_time(times.max),
        formatted_average: format_swim_time(calculate_average_time(user_practice_times))
      },
      distance_stats: {
        completed_distance: user_practice_times.count * practice_log.distance,
        expected_distance: practice_log.rep_count * practice_log.set_count * practice_log.distance,
        formatted_completed: "#{user_practice_times.count * practice_log.distance}m",
        formatted_expected: "#{practice_log.rep_count * practice_log.set_count * practice_log.distance}m"
      }
    }
  end

  def build_practice_statistics
    user_id = current_user_auth.user.id
    
    # 全体統計
    all_practice_times = PracticeTime.joins(:practice_log)
                                   .where(user_id: user_id)
    
    # 最近30日の統計
    recent_practice_times = all_practice_times.joins(practice_log: :attendance_event)
                                            .where("events.date >= ?", 30.days.ago)
    
    # 種目別統計
    style_stats = {}
    PracticeLog::STYLE_OPTIONS.each do |style_key, style_name|
      style_times = all_practice_times.joins(:practice_log)
                                    .where(practice_logs: { style: style_key })
      
      if style_times.any?
        times = style_times.pluck(:time)
        style_stats[style_key] = {
          name: style_name,
          total_times: times.count,
          best_time: times.min,
          average_time: times.sum / times.count.to_f,
          formatted_best: format_swim_time(times.min),
          formatted_average: format_swim_time(times.sum / times.count.to_f)
        }
      end
    end

    {
      total_practice_sessions: PracticeLog.joins(:practice_times)
                                        .where(practice_times: { user_id: user_id })
                                        .distinct
                                        .count,
      total_times_recorded: all_practice_times.count,
      recent_sessions: recent_practice_times.joins(:practice_log).distinct.count('practice_logs.id'),
      recent_times: recent_practice_times.count,
      style_statistics: style_stats,
      latest_practice: all_practice_times.joins(practice_log: :attendance_event)
                                       .order("events.date DESC")
                                       .first&.practice_log&.attendance_event&.date
    }
  end

  def build_practice_analytics(user_practice_times, practice_log)
    times = user_practice_times.map(&:time)
    
    # ペース分析
    target_pace = practice_log.circle > 0 ? practice_log.circle : nil
    pace_analysis = if target_pace
      faster_than_target = times.count { |t| t < target_pace }
      on_target = times.count { |t| (t - target_pace).abs < 1.0 } # 1秒以内
      
      {
        target_pace: target_pace,
        formatted_target: format_swim_time(target_pace),
        faster_count: faster_than_target,
        on_target_count: on_target,
        slower_count: times.count - faster_than_target - on_target,
        average_deviation: (times.sum - target_pace * times.count) / times.count.to_f
      }
    else
      nil
    end

    # 改善トレンド分析（セット間での改善）
    sets_data = user_practice_times.group_by(&:set_number)
    trend_analysis = if sets_data.count > 1
      set_averages = sets_data.map do |set_num, set_times|
        { set: set_num, average: calculate_average_time(set_times) }
      end.sort_by { |s| s[:set] }
      
      first_set_avg = set_averages.first[:average]
      last_set_avg = set_averages.last[:average]
      
      {
        improvement: last_set_avg < first_set_avg,
        time_change: last_set_avg - first_set_avg,
        percentage_change: ((last_set_avg - first_set_avg) / first_set_avg * 100).round(2),
        set_progression: set_averages
      }
    else
      nil
    end

    {
      pace_analysis: pace_analysis,
      trend_analysis: trend_analysis,
      consistency_score: calculate_consistency_score(user_practice_times)&.to_f,
      fatigue_index: calculate_fatigue_index(user_practice_times)&.to_f
    }
  end

  def calculate_average_time(times)
    return 0.0 if times.empty?
    times.sum(&:time) / times.count.to_f
  end

  def calculate_time_variance(times)
    return 0.0 if times.count < 2
    
    times_array = times.map(&:time)
    mean = times_array.sum / times_array.count.to_f
    variance = times_array.sum { |t| (t - mean) ** 2 } / times_array.count.to_f
    Math.sqrt(variance)
  end

  def calculate_consistency_score(times)
    return 100.0 if times.count < 2
    
    times_array = times.map(&:time)
    mean = times_array.sum / times_array.count.to_f
    variance = calculate_time_variance(times)
    
    # 一貫性スコア：変動係数の逆数（低いほど一貫している）
    coefficient_of_variation = variance / mean
    consistency = (1 / (1 + coefficient_of_variation)) * 100
    consistency.round(1)
  end

  def calculate_fatigue_index(times)
    return 0.0 if times.count < 2
    
    # 最初の25%と最後の25%の平均を比較
    count = times.count
    first_quarter_count = [count / 4, 1].max
    last_quarter_count = [count / 4, 1].max
    
    sorted_times = times.sort_by(&:rep_number)
    first_quarter = sorted_times.first(first_quarter_count)
    last_quarter = sorted_times.last(last_quarter_count)
    
    first_avg = calculate_average_time(first_quarter)
    last_avg = calculate_average_time(last_quarter)
    
    # 疲労指数：後半が前半より何％遅くなったか
    ((last_avg - first_avg) / first_avg * 100).round(2)
  end

  def format_swim_time(time_in_seconds)
    return nil unless time_in_seconds&.positive?
    
    minutes = (time_in_seconds / 60).to_i
    seconds = time_in_seconds % 60
    
    if minutes > 0
      "#{minutes}:#{sprintf('%05.2f', seconds)}"
    else
      sprintf('%.2f', seconds)
    end
  end
end
