class Api::V1::Admin::AttendancesController < Api::V1::Admin::BaseController
  before_action :set_attendance_event, only: [ :update_check ]

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
    users = User.where(user_type: "player").order(:generation, :name)

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
      return render_error("イベントIDが必要です", status: :bad_request)
    end

    # イベントの存在確認
    begin
      @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    rescue ActiveRecord::RecordNotFound
      return render_error("イベントが見つかりません", status: :not_found)
    end

    # 「出席」「その他」で登録済みの人を取得
    attendances = @attendance_event.attendances
                                  .includes(:user)
                                  .where(status: [ "present", "other" ])
                                  .joins(:user)
                                  .where(users: { user_type: "player" })
                                  .order("users.generation", "users.name")

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
    # Strong Parametersでチェック済みユーザーIDを安全に取得
    checked_user_ids = safe_checked_user_ids

    unless checked_user_ids.present?
      return render_error(I18n.t("api.admin.attendances.errors.checked_users_required"), status: :bad_request)
    end

    # 出席予定者の全ユーザーID
    all_present_user_ids = @attendance_event.attendances
                                           .where(status: [ "present", "other" ])
                                           .joins(:user)
                                           .where(users: { user_type: "player" })
                                           .pluck(:user_id)

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
      }, I18n.t("api.admin.attendances.messages.confirm_attendance", count: unchecked_user_ids.count))
    else
      render_success({
        has_unchecked_users: false
      }, I18n.t("api.admin.attendances.messages.all_present"))
    end
  end

  # POST /api/v1/admin/attendances/save_check
  def save_check
    # Strong Parametersで安全にパラメータを取得
    save_check_params = attendance_save_check_params

    unless save_check_params[:attendance_event_id].present? && save_check_params[:updates].present?
      return render_error(I18n.t("api.admin.attendances.errors.missing_parameters"), status: :bad_request)
    end

    # アップデートデータの正規化と検証
    normalized_updates = normalize_and_validate_updates(save_check_params[:updates])

    if normalized_updates[:errors].any?
      return render_error(I18n.t("api.admin.attendances.errors.invalid_updates"), status: :bad_request, errors: normalized_updates[:errors])
    end

    attendance_event = AttendanceEvent.find(save_check_params[:attendance_event_id])
    update_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      normalized_updates[:data].each_with_index do |update_data, index|
        user_id = safe_user_id(update_data[:user_id])
        status = update_data[:status]
        note = update_data[:note]

        # 必須フィールドの検証
        unless user_id.present? && status.present?
          errors << I18n.t("api.admin.attendances.errors.invalid_update_payload", index: index + 1, reason: "missing required fields")
          next
        end

        attendance = Attendance.find_by(user_id: user_id, attendance_event: attendance_event)
        if attendance
          if attendance.update(status: status, note: note || "")
            update_count += 1
          else
            errors << I18n.t("api.admin.attendances.errors.update_failed", user_id: user_id, errors: attendance.errors.full_messages.join(", "))
          end
        else
          errors << I18n.t("api.admin.attendances.errors.attendance_not_found", user_id: user_id)
        end
      end

      # 実際のレコード更新エラーのみでロールバック
      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      render_error(I18n.t("api.admin.attendances.errors.update_error"), status: :unprocessable_entity, errors: errors)
    else
      render_success({
        updated_count: update_count
      }, I18n.t("api.admin.attendances.messages.attendance_updated", count: update_count))
    end
  rescue ActiveRecord::RecordNotFound
    render_error(I18n.t("api.admin.attendances.errors.event_not_found"), status: :not_found)
  end

  # GET /api/v1/admin/attendances/status
  def status
    # 出欠受付管理画面用のデータを取得（N+1問題を回避するためeager loadingを使用）
    attendance_events = AttendanceEvent.includes(:attendances).order(date: :desc)
    competitions = Competition.includes(:entries).order(date: :desc)

    render_success({
      attendance_events: attendance_events.map do |event|
        {
          id: event.id,
          title: event.title,
          date: event.date,
          attendance_status: event.attendance_status,
          attendances_count: event.attendances.size
        }
      end,
      competitions: competitions.map do |competition|
        {
          id: competition.id,
          title: competition.title,
          date: competition.date,
          attendance_status: competition.attendance_status,
          entry_status: competition.entry_status,
          entries_count: competition.entries.size
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
      return render_error("更新データが必要です", status: :bad_request)
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
      render_error("出欠受付状況の更新中にエラーが発生しました", status: :unprocessable_entity, errors: errors)
    else
      render_success({
        updated_count: updated_count
      }, "出欠受付状況を更新しました")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("指定されたイベントが見つかりません", status: :not_found)
  end

  private

  def set_attendance_event
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
  rescue ActiveRecord::RecordNotFound
    render_error("イベントが見つかりません", status: :not_found)
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
    # 事前にロードされた出席データからインメモリインデックスを構築
    attendance_index = {}
    monthly_events.each do |event|
      attendance_index[event.id] = {}
      event.attendances.each do |attendance|
        attendance_index[event.id][attendance.user_id] = attendance.status
      end
    end

    # インデックスを使用して出席データを構築
    monthly_attendance_data = {}
    users.each do |user|
      monthly_attendance_data[user.id] = {}
      monthly_events.each do |event|
        monthly_attendance_data[user.id][event.id] = attendance_index[event.id][user.id] || "no_response"
      end
    end
    monthly_attendance_data
  end

  def sort_users_by_attendance(users, monthly_attendance_data, monthly_events, sort_by)
    if sort_by == "attendance_rate" && monthly_events.any?
      users.sort_by do |user|
        present_count = monthly_attendance_data[user.id].values.count("present")
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
      present_count: event.attendances.where(status: "present").count,
      absent_count: event.attendances.where(status: "absent").count,
      other_count: event.attendances.where(status: "other").count
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
    present_count = monthly_attendance_data[user.id].values.count("present")
    total_events = monthly_attendance_data[user.id].values.count { |status| status != "no_response" }
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

  # Strong Parameters
  def attendance_save_check_params
    params.permit(:attendance_event_id, updates: [ :user_id, :status, :note ])
  end

  # セーフなチェック済みユーザーIDの取得
  def safe_checked_user_ids
    checked_users = Array(params.fetch(:checked_users, []))
    checked_users.map do |user_id|
      safe_user_id(user_id)
    end.compact
  end

  # セーフなユーザーIDの変換
  def safe_user_id(user_id)
    return nil if user_id.blank?

    # 文字列に変換してから整数に変換
    user_id_str = user_id.to_s.strip
    return nil if user_id_str.empty?

    # 数値のみを許可
    return nil unless user_id_str.match?(/\A\d+\z/)

    user_id_str.to_i
  rescue => e
    Rails.logger.warn "Invalid user_id format: #{user_id.inspect}, error: #{e.message}"
    nil
  end

  # アップデートデータの正規化と検証
  def normalize_and_validate_updates(updates_param)
    errors = []
    normalized_data = []

    # アップデートデータが存在することを確認
    unless updates_param.present?
      errors << I18n.t("api.admin.attendances.errors.updates_missing")
      return { data: [], errors: errors }
    end

    # 配列に正規化
    updates_array = case updates_param
    when Array
      updates_param
    when String
      begin
        JSON.parse(updates_param)
      rescue JSON::ParserError => e
        errors << I18n.t("api.admin.attendances.errors.invalid_json", error: e.message)
        return { data: [], errors: errors }
      end
    else
      errors << I18n.t("api.admin.attendances.errors.invalid_updates_format")
      return { data: [], errors: errors }
    end

    # 各アップデートエントリを検証
    updates_array.each_with_index do |update_entry, index|
      unless update_entry.is_a?(Hash)
        errors << I18n.t("api.admin.attendances.errors.invalid_update_entry", index: index + 1)
        next
      end

      # 入力データを正規化（indifferent-access hashに変換）
      permitted_update = if update_entry.respond_to?(:permit)
        # Strong Parametersオブジェクトの場合
        update_entry.permit(:user_id, :status, :note).to_h.with_indifferent_access
      else
        # プレーンハッシュの場合
        update_entry.to_h.with_indifferent_access.slice(:user_id, :status, :note)
      end

      # 必須フィールドの検証
      unless permitted_update[:user_id].present?
        errors << I18n.t("api.admin.attendances.errors.missing_user_id", index: index + 1)
        next
      end

      unless permitted_update[:status].present?
        errors << I18n.t("api.admin.attendances.errors.missing_status", index: index + 1)
        next
      end

      # 有効なステータス値の検証
      valid_statuses = [ "present", "absent", "other" ]
      unless valid_statuses.include?(permitted_update[:status].to_s)
        errors << I18n.t("api.admin.attendances.errors.invalid_status", index: index + 1, status: permitted_update[:status])
        next
      end

      normalized_data << permitted_update
    end

    { data: normalized_data, errors: errors }
  end
end
