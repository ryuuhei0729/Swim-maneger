class Api::V1::Admin::PracticesController < Api::V1::Admin::BaseController
  before_action :set_practice_log, only: [:show, :edit, :update, :destroy]

  # GET /api/v1/admin/practices
  def index
    practice_logs = PracticeLog.includes(attendance_event: { attendances: :user })
                               .joins(:attendance_event)
                               .order("attendance_events.date DESC")
                               .limit(20)
    
    # 各練習記録の参加者数を計算
    practice_logs_with_counts = practice_logs.map do |log|
      attendees_count = log.attendance_event.attendances
                           .select { |attendance| 
                             ['present', 'other'].include?(attendance.status) && 
                             attendance.user.user_type == 'player' 
                           }
                           .count
      serialize_practice_log(log).merge(attendees_count: attendees_count)
    end

    render_success({
      practice_logs: practice_logs_with_counts,
      total_count: practice_logs.count
    })
  end

  # GET /api/v1/admin/practices/:id
  def show
    practice_times_by_user = @practice_log.practice_times.includes(:user).group_by(&:user)
    
    render_success({
      practice_log: serialize_practice_log_detail(@practice_log),
      practice_times_by_user: practice_times_by_user.transform_keys { |user| user.name }.transform_values do |times|
        times.group_by(&:set_number).transform_values do |set_times|
          set_times.sort_by(&:rep_number).map do |time|
            {
              rep_number: time.rep_number,
              time: time.time,
              formatted_time: format_time(time.time)
            }
          end
        end
      end
    })
  end

  # GET /api/v1/admin/practices/:id/edit
  def edit
    practice_times_by_user = @practice_log.practice_times.includes(:user).group_by(&:user)
    
    render_success({
      practice_log: serialize_practice_log_detail(@practice_log),
      styles: PracticeLog::STYLE_OPTIONS,
      practice_times_by_user: practice_times_by_user.transform_keys { |user| user.id }.transform_values do |times|
        times.group_by(&:set_number).transform_values do |set_times|
          set_times.sort_by(&:rep_number).map do |time|
            {
              id: time.id,
              rep_number: time.rep_number,
              time: time.time,
              formatted_time: format_time(time.time)
            }
          end
        end
      end
    })
  end

  # PATCH /api/v1/admin/practices/:id
  def update
    PracticeLog.transaction do
      @practice_log.update!(practice_log_params)

      # 既存のタイムを削除
      @practice_log.practice_times.destroy_all

      # 新しいタイムを保存
      if params[:times].present?
        save_practice_times(@practice_log, params[:times])
      end

      render_success({
        practice_log: serialize_practice_log(@practice_log)
      }, "練習記録を更新しました")
    rescue ActiveRecord::RecordInvalid => e
      render_error("練習記録の更新に失敗しました", :unprocessable_entity, @practice_log.errors.as_json)
    end
  end

  # DELETE /api/v1/admin/practices/:id
  def destroy
    @practice_log.destroy
    render_success({}, "練習記録を削除しました")
  end

  # GET /api/v1/admin/practices/time_setup
  def time_setup
    today = Date.today
    attendance_events = AttendanceEvent.order(date: :desc)
    default_event = attendance_events.where("date <= ?", today).first || attendance_events.first
    
    render_success({
      attendance_events: attendance_events.map { |event| serialize_event_basic(event) },
      default_event: default_event ? serialize_event_basic(default_event) : nil,
      styles: PracticeLog::STYLE_OPTIONS
    })
  end

  # POST /api/v1/admin/practices/time_preview
  def time_preview
    practice_log = PracticeLog.new(practice_log_get_params)
    
    unless practice_log.rep_count.present? && practice_log.set_count.present?
      return render_error("本数とセット数を入力してください", :bad_request)
    end

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
      event: event ? serialize_event_basic(event) : nil,
      attendees: attendees.map { |user| serialize_user_basic(user) }
    })
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  # POST /api/v1/admin/practices/time_save
  def time_save
    practice_log = PracticeLog.new(practice_log_params)

    PracticeLog.transaction do
      practice_log.save!

      # タイムデータが存在する場合は保存
      if params[:times].present?
        save_practice_times(practice_log, params[:times])
      end

      render_success({
        practice_log: serialize_practice_log(practice_log),
        times_count: practice_log.practice_times.count
      }, "練習タイムとメニューを保存しました", :created)
    rescue ActiveRecord::RecordInvalid => e
      render_error("練習データの保存に失敗しました", :unprocessable_entity, practice_log.errors.as_json)
    end
  end

  # POST /api/v1/admin/practices/attendees
  def manage_attendees
    event_id = params[:event_id]&.to_i
    action_type = params[:action_type] # 'add' or 'remove'
    attendee_id = params[:attendee_id]&.to_i

    unless event_id.present? && action_type.in?(['add', 'remove']) && attendee_id.present?
      return render_error("無効なパラメータです", :bad_request)
    end

    event = AttendanceEvent.find(event_id)
    user = User.find(attendee_id)

    ActiveRecord::Base.transaction do
      case action_type
      when 'add'
        # 既存の出席記録を確認
        attendance = event.attendances.find_or_initialize_by(user: user)
        if attendance.new_record?
          attendance.status = 'present'
          attendance.save!
        elsif attendance.status == 'absent'
          attendance.update!(status: 'present')
        end
        
      when 'remove'
        # 出席記録を欠席に変更
        attendance = event.attendances.find_or_initialize_by(user: user)
        attendance.status = 'absent'
        attendance.save!
      end
    end

    # 更新後の参加者リストを取得
    updated_attendees = get_current_attendees(event)

    render_success({
      action: action_type,
      attendee_id: attendee_id,
      current_attendees: updated_attendees.map { |user| serialize_user_basic(user) }
    }, "参加者リストを更新しました")
  rescue ActiveRecord::RecordNotFound
    render_error("イベントまたはユーザーが見つかりません", :not_found)
  rescue => e
    render_error("参加者リストの更新に失敗しました", :unprocessable_entity)
  end

  # GET /api/v1/admin/practices/register_setup
  def register_setup
    today = Date.today
    attendance_events = AttendanceEvent.order(date: :desc)
    default_event = attendance_events.where("date <= ?", today).first || attendance_events.first
    
    render_success({
      attendance_events: attendance_events.map { |event| serialize_event_basic(event) },
      default_event: default_event ? serialize_event_basic(default_event) : nil
    })
  end

  # POST /api/v1/admin/practices/register
  def create_register
    unless params[:attendance_event_id].present?
      return render_error("イベントIDが必要です", :bad_request)
    end

    attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    
    if attendance_event.update(attendance_event_image_params)
      render_success({
        event: serialize_event_basic(attendance_event)
      }, "練習メニュー画像を更新しました")
    else
      render_error("練習メニュー画像の更新に失敗しました", :unprocessable_entity, attendance_event.errors.as_json)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  # GET /api/v1/admin/practices/attendees_list
  def attendees_list
    unless params[:event_id].present?
      return render_error("イベントIDが必要です", :bad_request)
    end

    event = AttendanceEvent.find(params[:event_id])
    
    # 現在の参加者リストを取得
    current_attendees = get_current_attendees(event)
    
    # 欠席者のIDリストを取得
    absent_attendee_ids = event.attendances.includes(:user)
                               .where(status: "absent")
                               .joins(:user)
                               .where(users: { user_type: "player" })
                               .pluck(:user_id)

    # 出席可能な全ユーザー（追加候補用）
    all_players = User.where(user_type: 'player').order(:generation, :name)
    available_for_add = all_players.reject { |user| current_attendees.include?(user) }

    render_success({
      event: serialize_event_basic(event),
      current_attendees: current_attendees.map { |user| serialize_user_basic(user) },
      available_for_add: available_for_add.map { |user| serialize_user_basic(user) },
      absent_attendee_ids: absent_attendee_ids
    })
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  private

  def set_practice_log
    @practice_log = PracticeLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("練習記録が見つかりません", :not_found)
  end

  def practice_log_params
    params.require(:practice_log).permit(:attendance_event_id, :style, :rep_count, :set_count, :distance, :circle, :note)
  end

  def practice_log_get_params
    params.permit(:attendance_event_id, :rep_count, :set_count, :circle)
  end

  def attendance_event_image_params
    params.require(:attendance_event).permit(:menu_image)
  end

  def serialize_practice_log(log)
    {
      id: log.id,
      style: log.style,
      style_label: PracticeLog::STYLE_OPTIONS[log.style],
      distance: log.distance,
      rep_count: log.rep_count,
      set_count: log.set_count,
      circle: log.circle,
      note: log.note,
      created_at: log.created_at,
      updated_at: log.updated_at,
      event: {
        id: log.attendance_event.id,
        title: log.attendance_event.title,
        date: log.attendance_event.date
      }
    }
  end

  def serialize_practice_log_detail(log)
    serialize_practice_log(log).merge({
      practice_times_count: log.practice_times.count,
      participants_count: log.practice_times.distinct.count(:user_id)
    })
  end

  def serialize_event_basic(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      is_competition: event.is_competition
    }
  end

  def serialize_user_basic(user)
    {
      id: user.id,
      name: user.name,
      generation: user.generation,
      user_type: user.user_type
    }
  end

  def save_practice_times(practice_log, times_params)
    times_params.each do |user_id, set_data|
      set_data.each do |set_number, rep_data|
        rep_data.each do |rep_number, time|
          next if time.blank?

          # 時間を秒に変換 (MM:SS.ss or SS.ss)
          total_seconds = parse_time_to_seconds(time)

          PracticeTime.create!(
            user_id: user_id,
            practice_log_id: practice_log.id,
            set_number: set_number,
            rep_number: rep_number,
            time: total_seconds
          )
        end
      end
    end
  end

  def parse_time_to_seconds(time_string)
    return 0.0 if time_string.blank?
    
    if time_string.include?(":")
      minutes, seconds_part = time_string.split(":", 2)
      minutes.to_i * 60 + seconds_part.to_f
    else
      time_string.to_f
    end
  end

  def format_time(time_seconds)
    return "" if time_seconds.blank?
    
    minutes = (time_seconds / 60).to_i
    seconds = (time_seconds % 60)
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end

  def get_current_attendees(event)
    event.attendances.includes(:user)
         .where(status: ["present", "other"])
         .joins(:user)
         .where(users: { user_type: "player" })
         .map(&:user)
         .sort_by { |user| [user.generation, user.name] }
  end
end
