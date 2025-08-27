class HeavyQueryJob < ApplicationJob
  queue_as :default

  def perform(query_name, params, cache_key)
    Rails.logger.info "重いクエリ処理開始: #{query_name}"
    
    begin
      # クエリ名に応じて適切な処理を実行
      result = case query_name
               when 'user_statistics'
                 calculate_user_statistics(params)
               when 'team_performance'
                 calculate_team_performance(params)
               when 'competition_analysis'
                 analyze_competition_results(params)
               when 'practice_trends'
                 analyze_practice_trends(params)
               when 'attendance_reports'
                 generate_attendance_reports(params)
               else
                 Rails.logger.warn "未知のクエリ名: #{query_name}"
                 nil
               end
      
      # 結果をキャッシュに保存
      if result
        Rails.cache.write(cache_key, result, expires_in: 1.hour)
        Rails.logger.info "重いクエリ処理完了: #{query_name}"
      else
        Rails.logger.error "重いクエリ処理失敗: #{query_name}"
      end
      
    rescue => e
      Rails.logger.error "重いクエリ処理エラー: #{query_name} - #{e.message}"
      Rails.cache.delete("#{cache_key}:processing")
    end
  end

  private

  def calculate_user_statistics(params)
    user_id = params['user_id']
    date_range = params['date_range']
    
    user = User.find(user_id)
    start_date = date_range['start_date']&.to_date || 30.days.ago.to_date
    end_date = date_range['end_date']&.to_date || Date.current
    
    {
      total_practices: user.practice_logs.where(created_at: start_date..end_date).count,
      total_events: user.attendances.joins(:attendance_event)
                      .where(attendance_events: { date: start_date..end_date }).count,
      attendance_rate: calculate_attendance_rate(user, start_date, end_date),
      best_times: user.records.includes(:style)
                      .where(created_at: start_date..end_date)
                      .group_by(&:style)
                      .transform_values { |records| records.min_by(&:time)&.time },
      recent_improvements: calculate_recent_improvements(user, start_date, end_date)
    }
  end

  def calculate_team_performance(params)
    date_range = params['date_range']
    start_date = date_range['start_date']&.to_date || 30.days.ago.to_date
    end_date = date_range['end_date']&.to_date || Date.current
    
    {
      total_members: User.where(user_type: 'player').count,
      active_members: User.joins(:attendances)
                         .where(user_type: 'player')
                         .where(attendances: { created_at: start_date..end_date })
                         .distinct.count,
      average_attendance_rate: calculate_average_attendance_rate(start_date, end_date),
      top_performers: find_top_performers(start_date, end_date),
      practice_statistics: calculate_practice_statistics(start_date, end_date)
    }
  end

  def analyze_competition_results(params)
    competition_id = params['competition_id']
    competition = Event.find(competition_id)
    
    {
      total_participants: competition.entries.count,
      results_by_style: competition.entries.joins(:style)
                                   .group('styles.name')
                                   .count,
      performance_trends: analyze_performance_trends(competition),
      medal_distribution: calculate_medal_distribution(competition)
    }
  end

  def analyze_practice_trends(params)
    date_range = params['date_range']
    start_date = date_range['start_date']&.to_date || 30.days.ago.to_date
    end_date = date_range['end_date']&.to_date || Date.current
    
    {
      daily_participation: calculate_daily_participation(start_date, end_date),
      style_distribution: calculate_style_distribution(start_date, end_date),
      time_improvements: calculate_time_improvements(start_date, end_date),
      popular_practices: find_popular_practices(start_date, end_date)
    }
  end

  def generate_attendance_reports(params)
    date_range = params['date_range']
    start_date = date_range['start_date']&.to_date || 30.days.ago.to_date
    end_date = date_range['end_date']&.to_date || Date.current
    
    {
      overall_attendance: calculate_overall_attendance(start_date, end_date),
      attendance_by_generation: calculate_attendance_by_generation(start_date, end_date),
      attendance_by_event_type: calculate_attendance_by_event_type(start_date, end_date),
      attendance_trends: calculate_attendance_trends(start_date, end_date)
    }
  end

  # ヘルパーメソッド群
  def calculate_attendance_rate(user, start_date, end_date)
    total_events = AttendanceEvent.where(date: start_date..end_date).count
    attended_events = user.attendances.joins(:attendance_event)
                          .where(attendance_events: { date: start_date..end_date })
                          .where(status: 'present').count
    
    total_events > 0 ? (attended_events.to_f / total_events * 100).round(2) : 0
  end

  def calculate_recent_improvements(user, start_date, end_date)
    user.records.includes(:style)
        .where(created_at: start_date..end_date)
        .group_by(&:style)
        .transform_values do |records|
          sorted_records = records.sort_by(&:created_at)
          if sorted_records.length >= 2
            first_time = sorted_records.first.time
            last_time = sorted_records.last.time
            improvement = first_time - last_time
            { improvement: improvement, percentage: (improvement / first_time * 100).round(2) }
          else
            { improvement: 0, percentage: 0 }
          end
        end
  end

  def calculate_average_attendance_rate(start_date, end_date)
    users = User.where(user_type: 'player')
    total_rate = users.sum { |user| calculate_attendance_rate(user, start_date, end_date) }
    users.count > 0 ? (total_rate.to_f / users.count).round(2) : 0
  end

  def find_top_performers(start_date, end_date)
    User.joins(:records)
        .where(user_type: 'player')
        .where(records: { created_at: start_date..end_date })
        .group('users.id')
        .order('COUNT(records.id) DESC')
        .limit(10)
        .pluck(:name, 'COUNT(records.id)')
  end

  def calculate_practice_statistics(start_date, end_date)
    {
      total_practices: PracticeLog.where(created_at: start_date..end_date).count,
      average_participants: PracticeLog.joins(:practice_times)
                                      .where(created_at: start_date..end_date)
                                      .group('practice_logs.id')
                                      .average('practice_times.count')
                                      .values
                                      .compact
                                      .sum / PracticeLog.where(created_at: start_date..end_date).count
    }
  end

  def analyze_performance_trends(competition)
    # 大会のパフォーマンストレンド分析
    competition.entries.includes(:user, :style)
              .group_by(&:style)
              .transform_values do |entries|
                entries.map(&:time).compact
              end
  end

  def calculate_medal_distribution(competition)
    # メダル分布の計算（仮実装）
    { gold: 0, silver: 0, bronze: 0 }
  end

  def calculate_daily_participation(start_date, end_date)
    PracticeLog.where(created_at: start_date..end_date)
               .group_by { |log| log.created_at.to_date }
               .transform_values(&:count)
  end

  def calculate_style_distribution(start_date, end_date)
    PracticeLog.joins(:style)
               .where(created_at: start_date..end_date)
               .group('styles.name')
               .count
  end

  def calculate_time_improvements(start_date, end_date)
    # タイム改善の分析
    Record.where(created_at: start_date..end_date)
          .group_by(&:style)
          .transform_values do |records|
            records.sort_by(&:created_at)
          end
  end

  def find_popular_practices(start_date, end_date)
    PracticeLog.where(created_at: start_date..end_date)
               .group(:menu)
               .order('COUNT(*) DESC')
               .limit(10)
               .pluck(:menu, 'COUNT(*)')
  end

  def calculate_overall_attendance(start_date, end_date)
    total_events = AttendanceEvent.where(date: start_date..end_date).count
    total_attendances = Attendance.joins(:attendance_event)
                                 .where(attendance_events: { date: start_date..end_date })
                                 .where(status: 'present').count
    
    total_events > 0 ? (total_attendances.to_f / total_events).round(2) : 0
  end

  def calculate_attendance_by_generation(start_date, end_date)
    User.joins(:attendances)
        .joins(:attendance_events)
        .where(user_type: 'player')
        .where(attendance_events: { date: start_date..end_date })
        .group(:generation)
        .count
  end

  def calculate_attendance_by_event_type(start_date, end_date)
    AttendanceEvent.where(date: start_date..end_date)
                   .group(:event_type)
                   .count
  end

  def calculate_attendance_trends(start_date, end_date)
    AttendanceEvent.where(date: start_date..end_date)
                   .group_by { |event| event.date.beginning_of_week }
                   .transform_values do |events|
                     events.sum { |event| event.attendances.where(status: 'present').count }
                   end
  end
end
