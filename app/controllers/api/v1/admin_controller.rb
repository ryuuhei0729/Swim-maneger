class Api::V1::AdminController < Api::V1::BaseController
  before_action :check_admin_access

  def index
    render_success({
      message: "管理者ダッシュボード"
    })
  end

  # ======= ユーザー作成機能 =======
  def users
    users = User.includes(:user_auth).order(:generation, :name)
    
    render_success({
      users: users.map do |user|
        {
          id: user.id,
          name: user.name,
          user_type: user.user_type,
          generation: user.generation,
          gender: user.gender,
          birthday: user.birthday,
          created_at: user.created_at,
          email: user.user_auth&.email
        }
      end
    })
  end

  def create_user
    user = User.new(user_params)
    user_auth = UserAuth.new(user_auth_params)

    User.transaction do
      if user.save
        user_auth.user = user
        if user_auth.save
          render_success({
            message: "ユーザーを作成しました",
            user: {
              id: user.id,
              name: user.name,
              user_type: user.user_type,
              generation: user.generation,
              email: user_auth.email
            }
          }, :created)
        else
          user.destroy
          render_error("ユーザー認証情報の作成に失敗しました", :unprocessable_entity, user_auth.errors)
        end
      else
        render_error("ユーザーの作成に失敗しました", :unprocessable_entity, user.errors)
      end
    end
  end

  # ======= お知らせ管理機能 =======
  def announcements
    announcements = Announcement.all.order(published_at: :desc)
    
    render_success({
      announcements: announcements.map do |announcement|
        {
          id: announcement.id,
          title: announcement.title,
          content: announcement.content,
          is_active: announcement.is_active,
          published_at: announcement.published_at,
          created_at: announcement.created_at
        }
      end
    })
  end

  def create_announcement
    announcement = Announcement.new(announcement_params)

    if announcement.save
      render_success({
        message: "お知らせを作成しました",
        announcement: {
          id: announcement.id,
          title: announcement.title,
          content: announcement.content,
          is_active: announcement.is_active,
          published_at: announcement.published_at
        }
      }, :created)
    else
      render_error("お知らせの作成に失敗しました", :unprocessable_entity, announcement.errors)
    end
  end

  def update_announcement
    announcement = Announcement.find(params[:id])

    if announcement.update(announcement_params)
      render_success({
        message: "お知らせを更新しました",
        announcement: {
          id: announcement.id,
          title: announcement.title,
          content: announcement.content,
          is_active: announcement.is_active,
          published_at: announcement.published_at
        }
      })
    else
      render_error("お知らせの更新に失敗しました", :unprocessable_entity, announcement.errors)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("お知らせが見つかりません", :not_found)
  end

  def destroy_announcement
    announcement = Announcement.find(params[:id])
    announcement.destroy

    render_success({
      message: "お知らせを削除しました"
    })
  rescue ActiveRecord::RecordNotFound
    render_error("お知らせが見つかりません", :not_found)
  end

  # ======= スケジュール管理機能 =======
  def schedules
    events = AttendanceEvent.order(date: :asc)
    
    render_success({
      events: events.map do |event|
        {
          id: event.id,
          title: event.title,
          date: event.date,
          is_competition: event.is_competition,
          note: event.note,
          place: event.place,
          created_at: event.created_at
        }
      end
    })
  end

  def create_schedule
    event = AttendanceEvent.new(schedule_params)
    
    if event.save
      render_success({
        message: "スケジュールを登録しました",
        event: {
          id: event.id,
          title: event.title,
          date: event.date,
          is_competition: event.is_competition,
          note: event.note,
          place: event.place
        }
      }, :created)
    else
      render_error("スケジュールの登録に失敗しました", :unprocessable_entity, event.errors)
    end
  end

  def update_schedule
    event = AttendanceEvent.find(params[:id])
    
    if event.update(schedule_params)
      render_success({
        message: "スケジュールを更新しました",
        event: {
          id: event.id,
          title: event.title,
          date: event.date,
          is_competition: event.is_competition,
          note: event.note,
          place: event.place
        }
      })
    else
      render_error("スケジュールの更新に失敗しました", :unprocessable_entity, event.errors)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("スケジュールが見つかりません", :not_found)
  end

  def destroy_schedule
    event = AttendanceEvent.find(params[:id])
    event.destroy
    
    render_success({
      message: "スケジュールを削除しました"
    })
  rescue ActiveRecord::RecordNotFound
    render_error("スケジュールが見つかりません", :not_found)
  end

  def show_schedule
    event = AttendanceEvent.find(params[:id])
    
    render_success({
      event: {
        id: event.id,
        title: event.title,
        date: event.date.strftime("%Y-%m-%d"),
        is_competition: event.is_competition,
        note: event.note,
        place: event.place
      }
    })
  rescue ActiveRecord::RecordNotFound
    render_error("スケジュールが見つかりません", :not_found)
  end

  # ======= 目標管理機能 =======
  def objectives
    objectives = Objective.includes(:user, :attendance_event, :style, :milestones)
                         .order("attendance_events.date DESC")
    
    render_success({
      objectives: objectives.map do |objective|
        {
          id: objective.id,
          user_name: objective.user.name,
          target_time: objective.target_time,
          event_title: objective.attendance_event.title,
          event_date: objective.attendance_event.date,
          style_name: objective.style.name_jp,
          quality_title: objective.quality_title,
          milestones_count: objective.milestones.count,
          created_at: objective.created_at
        }
      end
    })
  end

  # ======= 練習管理機能 =======
  def practice_time_setup
    today = Date.today
    attendance_events = AttendanceEvent.order(date: :desc)
    default_event = attendance_events.where("date <= ?", today).first || attendance_events.first
    
    render_success({
      attendance_events: attendance_events.map do |event|
        {
          id: event.id,
          title: event.title,
          date: event.date,
          is_competition: event.is_competition
        }
      end,
      default_event: default_event ? {
        id: default_event.id,
        title: default_event.title,
        date: default_event.date
      } : nil,
      styles: PracticeLog::STYLE_OPTIONS
    })
  end

  def practice_time_preview
    practice_log = PracticeLog.new(practice_log_get_params)
    
    if practice_log.rep_count.present? && practice_log.set_count.present?
      event_id = practice_log.attendance_event_id
      event = AttendanceEvent.find(event_id) if event_id.present?
      
      attendees = []
      if event
        attendees = event.attendances.includes(:user)
                        .where(status: ["present", "other"])
                        .joins(:user)
                        .where(users: { user_type: "player" })
                        .map(&:user)
                        .sort_by { |user| [user.generation, user.name] }
      end
      
      render_success({
        practice_log: {
          attendance_event_id: practice_log.attendance_event_id,
          rep_count: practice_log.rep_count,
          set_count: practice_log.set_count,
          circle: practice_log.circle
        },
        event: event ? {
          id: event.id,
          title: event.title,
          date: event.date
        } : nil,
        attendees: attendees.map do |user|
          {
            id: user.id,
            name: user.name,
            generation: user.generation
          }
        end
      })
    else
      render_error("練習設定が不完全です", :unprocessable_entity)
    end
  end

  def create_practice_log_and_times
    practice_log = PracticeLog.new(practice_log_params)

    PracticeLog.transaction do
      practice_log.save!

      times_params = params.require(:times)
      created_times = []
      
      times_params.each do |user_id, set_data|
        set_data.each do |set_number, rep_data|
          rep_data.each do |rep_number, time|
            next if time.blank?

            # 時間を秒に変換 (MM:SS.ss or SS.ss)
            total_seconds = 0.0
            if time.include?(":")
              minutes, seconds_part = time.split(":", 2)
              total_seconds = minutes.to_i * 60 + seconds_part.to_f
            else
              total_seconds = time.to_f
            end

            practice_time = PracticeTime.create!(
              user_id: user_id,
              practice_log_id: practice_log.id,
              set_number: set_number,
              rep_number: rep_number,
              time: total_seconds
            )
            created_times << practice_time
          end
        end
      end

      render_success({
        message: "練習タイムとメニューを保存しました",
        practice_log: {
          id: practice_log.id,
          style: practice_log.style,
          distance: practice_log.distance,
          rep_count: practice_log.rep_count,
          set_count: practice_log.set_count
        },
        times_count: created_times.count
      }, :created)
    rescue ActiveRecord::RecordInvalid => e
      render_error("練習データの保存に失敗しました", :unprocessable_entity, practice_log.errors)
    end
  end

  def practices
    practice_logs = PracticeLog.includes(:attendance_event)
                               .order("attendance_events.date DESC")
                               .limit(5)
    
    render_success({
      practice_logs: practice_logs.map do |log|
        {
          id: log.id,
          style: log.style,
          distance: log.distance,
          rep_count: log.rep_count,
          set_count: log.set_count,
          circle: log.circle,
          note: log.note,
          event_title: log.attendance_event.title,
          event_date: log.attendance_event.date,
          created_at: log.created_at
        }
      end
    })
  end

  def practice_register_setup
    today = Date.today
    attendance_events = AttendanceEvent.order(date: :desc)
    default_event = attendance_events.where("date <= ?", today).first || attendance_events.first
    
    render_success({
      attendance_events: attendance_events.map do |event|
        {
          id: event.id,
          title: event.title,
          date: event.date,
          is_competition: event.is_competition
        }
      end,
      default_event: default_event ? {
        id: default_event.id,
        title: default_event.title,
        date: default_event.date
      } : nil
    })
  end

  def create_practice_register
    attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    
    if attendance_event.update(attendance_event_image_params)
      render_success({
        message: "練習メニュー画像を更新しました",
        event: {
          id: attendance_event.id,
          title: attendance_event.title,
          date: attendance_event.date
        }
      })
    else
      render_error("練習メニュー画像の更新に失敗しました", :unprocessable_entity, attendance_event.errors)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?(["coach", "director"])
      render_error("管理者権限が必要です", :forbidden)
    end
  end

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday)
  end

  def user_auth_params
    if params[:user_auth].present?
      params.require(:user_auth).permit(:email, :password, :password_confirmation)
    else
      params.permit(:email, :password, :password_confirmation)
    end
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :is_active, :published_at)
  end

  def schedule_params
    params.require(:attendance_event).permit(:title, :date, :is_competition, :note, :place)
  end

  def attendance_event_image_params
    params.require(:attendance_event).permit(:menu_image)
  end

  def practice_log_params
    params.require(:practice_log).permit(:attendance_event_id, :style, :rep_count, :set_count, :distance, :circle, :note)
  end

  def practice_log_get_params
    params.permit(:attendance_event_id, :rep_count, :set_count, :circle)
  end
end 