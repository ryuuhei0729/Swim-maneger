class Api::V1::Admin::DashboardController < Api::V1::BaseController
  before_action :check_admin_access

  # GET /api/v1/admin/dashboard
  def index
    # 管理者ダッシュボードの統計データを取得
    dashboard_data = {
      summary: {
        total_users: User.count,
        active_players: User.where(user_type: 'player').count,
        total_events: Event.count,
        upcoming_events: Event.where('date >= ?', Date.current).count,
        total_announcements: Announcement.count,
        active_announcements: Announcement.where(is_active: true).count
      },
      recent_activities: {
        recent_users: User.order(created_at: :desc).limit(5).map do |user|
          {
            id: user.id,
            name: user.name,
            user_type: user.user_type,
            created_at: user.created_at
          }
        end,
        recent_announcements: Announcement.order(created_at: :desc).limit(3).map do |announcement|
          {
            id: announcement.id,
            title: announcement.title,
            is_active: announcement.is_active,
            created_at: announcement.created_at
          }
        end,
        upcoming_events: Event.where('date >= ?', Date.current)
                             .order(:date)
                             .limit(5)
                             .map do |event|
          {
            id: event.id,
            title: event.title,
            date: event.date,
            is_competition: event.is_competition
          }
        end
      },
      quick_stats: {
        this_month_practices: PracticeLog.joins(:attendance_event)
                                        .where(events: { date: Date.current.beginning_of_month..Date.current.end_of_month })
                                        .count,
        this_month_attendance_rate: calculate_monthly_attendance_rate,
        pending_objectives: Objective.joins(:milestones)
                                   .where(milestones: { limit_date: Date.current..1.week.from_now })
                                   .distinct
                                   .count
      }
    }

    render_success(dashboard_data, "管理者ダッシュボードデータを取得しました")
  end

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?(["coach", "director", "manager"])
      render_error("管理者権限が必要です", :forbidden)
    end
  end

  def calculate_monthly_attendance_rate
    current_month_events = Event.where(date: Date.current.beginning_of_month..Date.current.end_of_month)
    return 0 if current_month_events.empty?

    total_possible_attendances = current_month_events.count * User.where(user_type: 'player').count
    return 0 if total_possible_attendances.zero?

    actual_attendances = Attendance.joins(:attendance_event)
                                  .where(events: { date: Date.current.beginning_of_month..Date.current.end_of_month })
                                  .where(status: 'present')
                                  .count

    (actual_attendances.to_f / total_possible_attendances * 100).round(1)
  end
end
