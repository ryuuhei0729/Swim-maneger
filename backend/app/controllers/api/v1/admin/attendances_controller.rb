class Api::V1::Admin::AttendancesController < Api::V1::Admin::BaseController
  before_action :set_attendance_event, only: [:check, :update_check]

  # GET /api/v1/admin/attendances
  def index
    # 出欠管理画面用のイベント一覧
    events = AttendanceEvent.includes(:attendances)
                           .order(date: :desc)
                           .limit(20)
    
    # 当日出席確認用のイベント一覧
    today = Date.current
    check_events = AttendanceEvent.where(date: today - 7.days..today + 7.days).order(:date)
    default_check_event = check_events.where("date <= ?", today).last || check_events.first
    
    # 月別データの取得
    selected_month = parse_month(params[:month])
    monthly_events = AttendanceEvent.includes(:attendances)
                                   .where(date: selected_month..selected_month.end_of_month)
                                   .order(:date)
    
    # ユーザー一覧を取得（部員のみ）
    users = User.where(user_type: 'player').order(:generation, :name)
    
    # 月別の出欠データを整理
    monthly_attendance_data = build_monthly_attendance_data(users, monthly_events)
    
    # 並び替え処理
    sorted_users = sort_users_by_attendance(users, monthly_attendance_data, monthly_events, params[:sort_by])

    render_success({
      events: events.map { |event| serialize_event_summary(event) },
      check_events: check_events.map { |event| serialize_event_basic(event) },
      default_check_event: default_check_event ? serialize_event_basic(default_check_event) : nil,
      monthly_events: monthly_events.map { |event| serialize_event_basic(event) },
      users: sorted_users.map { |user| serialize_user_with_attendance(user, monthly_attendance_data) },
      selected_month: selected_month.strftime("%Y-%m")
    })
  end

  # GET /api/v1/admin/attendances/check
  def check
    unless params[:attendance_event_id].present?
      return render_error("イベントIDが必要です", :bad_request)
    end

    # 「出席」「その他」で登録済みの人を取得
    attendances = @attendance_event.attendances
                                  .includes(:user)
                                  .where(status: ['present', 'other'])
                                  .joins(:user)
                                  .where(users: { user_type: 'player' })
                                  .order('users.generation', 'users.name')

    render_success({
      event: serialize_event_basic(@attendance_event),
      attendances: attendances.map do |attendance|
        {
          id: attendance.id,
          user: {
            id: attendance.user.id,
            name: attendance.user.name,
            generation: attendance.user.generation
          },
          status: attendance.status,
          note: attendance.note,
          checked: true # デフォルトでチェック済みとする
        }
      end
    })
  end

  # PATCH /api/v1/admin/attendances/check
  def update_check
    unless params[:checked_users].present?
      return render_error("チェック済みユーザー情報が必要です", :bad_request)
    end

    # 出席予定者の全ユーザーID
    all_present_user_ids = @attendance_event.attendances
                                           .where(status: ['present', 'other'])
                                           .joins(:user)
                                           .where(users: { user_type: 'player' })
                                           .pluck(:user_id)
    
    # チェックされたユーザーID
    checked_user_ids = params[:checked_users].map(&:to_i)
    
    # チェックされなかった（実際には出席していない）ユーザーID
    unchecked_user_ids = all_present_user_ids - checked_user_ids
    
    if unchecked_user_ids.any?
      # 未チェックユーザーの情報を返す
      unchecked_users = User.where(id: unchecked_user_ids).order(:generation, :name)
      
      render_success({
        has_unchecked_users: true,
        unchecked_users: unchecked_users.map do |user|
          attendance = @attendance_event.attendances.find_by(user: user)
          {
            id: user.id,
            name: user.name,
            generation: user.generation,
            current_status: attendance&.status,
            current_note: attendance&.note
          }
        end,
        attendance_event_id: @attendance_event.id
      }, "#{unchecked_user_ids.count}人の出席状況を確認してください")
    else
      render_success({
        has_unchecked_users: false
      }, "全員が出席でした。変更はありません。")
    end
  end

  # POST /api/v1/admin/attendances/save_check
  def save_check
    unless params[:attendance_event_id].present? || params[:updates].present?
      return render_error("必要なパラメータが不足しています", :bad_request)
    end

    attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    updates = params[:updates]
    
    update_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      updates.each do |update_data|
        user_id = update_data[:user_id]
        status = update_data[:status]
        note = update_data[:note]
        
        next unless user_id.present? && status.present?
        
        attendance = Attendance.find_by(user_id: user_id, attendance_event: attendance_event)
        if attendance
          if attendance.update(status: status, note: note || "")
            update_count += 1
          else
            errors << "ユーザーID #{user_id}: #{attendance.errors.full_messages.join(', ')}"
          end
        else
          errors << "ユーザーID #{user_id}: 出欠記録が見つかりません"
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render_error("出席状況の更新中にエラーが発生しました", :unprocessable_entity, { errors: errors })
    else
      render_success({
        updated_count: update_count
      }, "#{update_count}人の出席状況を更新しました")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  # GET /api/v1/admin/attendances/status
  def status
    # 出欠受付管理画面用のデータを取得
    attendance_events = AttendanceEvent.order(date: :desc)
    competitions = Competition.order(date: :desc)

    render_success({
      attendance_events: attendance_events.map do |event|
        {
          id: event.id,
          title: event.title,
          date: event.date,
          attendance_status: event.attendance_status,
          attendances_count: event.attendances.count
        }
      end,
      competitions: competitions.map do |competition|
        {
          id: competition.id,
          title: competition.title,
          date: competition.date,
          attendance_status: competition.attendance_status,
          entry_status: competition.entry_status,
          entries_count: competition.entries.count
        }
      end,
      status_options: {
        attendance_event_statuses: AttendanceEvent.attendance_statuses,
        competition_statuses: Competition.attendance_statuses
      }
    })
  end

  # PATCH /api/v1/admin/attendances/status
  def update_status
    unless params[:updates].present?
      return render_error("更新データが必要です", :bad_request)
    end

    updates = params[:updates]
    updated_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      # AttendanceEventの更新
      if updates[:attendance_events].present?
        updates[:attendance_events].each do |event_id, status|
          next unless AttendanceEvent.attendance_statuses.key?(status.to_s)
          
          event = AttendanceEvent.find(event_id)
          if event.update(attendance_status: status)
            updated_count += 1
          else
            errors << "AttendanceEvent #{event_id}: #{event.errors.full_messages.join(', ')}"
          end
        end
      end

      # Competitionの更新
      if updates[:competitions].present?
        updates[:competitions].each do |event_id, status|
          next unless Competition.attendance_statuses.key?(status.to_s)
          
          event = Competition.find(event_id)
          if event.update(attendance_status: status)
            updated_count += 1
          else
            errors << "Competition #{event_id}: #{event.errors.full_messages.join(', ')}"
          end
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render_error("出欠受付状況の更新中にエラーが発生しました", :unprocessable_entity, { errors: errors })
    else
      render_success({
        updated_count: updated_count
      }, "出欠受付状況を更新しました")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("指定されたイベントが見つかりません", :not_found)
  end

  private

  def set_attendance_event
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", :not_found)
  end

  def parse_month(month_param)
    if month_param.present?
      begin
        month_str = "#{month_param}-01"
        Date.parse(month_str).beginning_of_month
      rescue Date::Error
        Date.current.beginning_of_month
      end
    else
      Date.current.beginning_of_month
    end
  end

  def build_monthly_attendance_data(users, monthly_events)
    monthly_attendance_data = {}
    users.each do |user|
      monthly_attendance_data[user.id] = {}
      monthly_events.each do |event|
        attendance = event.attendances.find_by(user: user)
        monthly_attendance_data[user.id][event.id] = attendance&.status || 'no_response'
      end
    end
    monthly_attendance_data
  end

  def sort_users_by_attendance(users, monthly_attendance_data, monthly_events, sort_by)
    if sort_by == 'attendance_rate' && monthly_events.any?
      users.sort_by do |user|
        present_count = monthly_attendance_data[user.id].values.count('present')
        total_events = monthly_events.count
        attendance_rate = total_events > 0 ? (present_count.to_f / total_events * 100) : 0
        -attendance_rate # 降順のため負の値
      end
    else
      users
    end
  end

  def serialize_event_summary(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      attendance_status: event.attendance_status,
      attendances_count: event.attendances.count,
      present_count: event.attendances.where(status: 'present').count,
      absent_count: event.attendances.where(status: 'absent').count,
      other_count: event.attendances.where(status: 'other').count
    }
  end

  def serialize_event_basic(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      attendance_status: event.attendance_status
    }
  end

  def serialize_user_with_attendance(user, monthly_attendance_data)
    present_count = monthly_attendance_data[user.id].values.count('present')
    total_events = monthly_attendance_data[user.id].values.count { |status| status != 'no_response' }
    attendance_rate = total_events > 0 ? (present_count.to_f / total_events * 100).round(1) : 0

    {
      id: user.id,
      name: user.name,
      generation: user.generation,
      user_type: user.user_type,
      attendance_data: monthly_attendance_data[user.id],
      attendance_rate: attendance_rate,
      present_count: present_count,
      total_events: total_events
    }
  end
end
