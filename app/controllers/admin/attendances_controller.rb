class Admin::AttendancesController < Admin::BaseController
  def index
    # 出欠管理画面用のデータを取得
    @events = AttendanceEvent.includes(:attendances)
                           .order(date: :desc)
                           .limit(20)
    
    # 当日出席確認用のイベント一覧とデフォルト選択
    today = Date.current
    @check_events = AttendanceEvent.where(date: today - 7.days..today + 7.days).order(:date)
    # 本日に最も近いイベントをデフォルトとする（過去の練習を優先）
    @default_check_event = @check_events.where("date <= ?", today).last || @check_events.first
    
    # ユーザー一覧を取得（部員のみ）
    @users = User.where(user_type: 'player')
                 .order(:generation, :name)
    
    # 月別出欠状況用のデータ
    begin
      if params[:month].present?
        # "2025-12" 形式のパラメータを "2025-12-01" に変換してからパース
        month_str = "#{params[:month]}-01"
        @selected_month = Date.parse(month_str).beginning_of_month
      else
        @selected_month = Date.current.beginning_of_month
      end
    rescue Date::Error
      @selected_month = Date.current.beginning_of_month
    end
    @monthly_events = AttendanceEvent.includes(:attendances)
                                   .where(date: @selected_month..@selected_month.end_of_month)
                                   .order(:date)
    
    # 月別の出欠データを整理
    @monthly_attendance_data = {}
    @users.each do |user|
      @monthly_attendance_data[user.id] = {}
      @monthly_events.each do |event|
        attendance = event.attendances.find_by(user: user)
        @monthly_attendance_data[user.id][event.id] = attendance&.status || 'no_response'
      end
    end
    
    # 並び替え処理
    @sort_by = params[:sort_by]
    if @sort_by == 'attendance_rate' && @monthly_events.any?
      # 参加率で並び替え（降順）
      @users = @users.sort_by do |user|
        present_count = @monthly_attendance_data[user.id].values.count('present')
        total_events = @monthly_events.count
        attendance_rate = total_events > 0 ? (present_count.to_f / total_events * 100) : 0
        -attendance_rate # 降順のため負の値
      end
    end
  end

  def check
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    # 「出席」「その他」で登録済みの人を取得
    @attendances = @attendance_event.attendances
                                  .includes(:user)
                                  .where(status: ['present', 'other'])
                                  .joins(:user)
                                  .where(users: { user_type: 'player' })
                                  .order('users.generation', 'users.name')
      rescue ActiveRecord::RecordNotFound
    redirect_to admin_attendance_path, alert: "イベントが見つかりません"
  end

  def update_check
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    
    # 出席予定者の全ユーザーID
    all_present_user_ids = @attendance_event.attendances
                                           .where(status: ['present', 'other'])
                                           .joins(:user)
                                           .where(users: { user_type: 'player' })
                                           .pluck(:user_id)
    
    # チェックされたユーザーID
    checked_user_ids = params[:checked_users]&.keys&.map(&:to_i) || []
    
    # チェックされなかった（実際には出席していない）ユーザーID
    unchecked_user_ids = all_present_user_ids - checked_user_ids
    
    if unchecked_user_ids.any?
      # 配列であることを保証
      unchecked_user_ids = Array(unchecked_user_ids)
      # 画面遷移でattendance_updateへリダイレクト（パラメータで渡す）
      render json: {
        success: true,
        redirect_url: admin_attendance_update_path(attendance_event_id: @attendance_event.id, unchecked_user_ids: unchecked_user_ids)
      }
      return
    else
      render json: {
        success: true,
        message: "全員が出席でした。変更はありません。"
      }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "イベントが見つかりません" }
  end

  def save_check
    begin
      ActiveRecord::Base.transaction do
        # セッションからデータを取得
        attendance_data = session[:unchecked_attendance_data]
        unless attendance_data
          render json: { success: false, message: "セッションデータが見つかりません" }
          return
        end

        attendance_event = AttendanceEvent.find(attendance_data['attendance_event_id'])
        unchecked_user_ids = attendance_data['unchecked_user_ids']
        
        # パラメータから各ユーザーの状況を取得して更新
        update_count = 0
        unchecked_user_ids.each do |user_id|
          status_param = "status_#{user_id}"
          note_param = "note_#{user_id}"
          
          next unless params[status_param].present?
          
          attendance = Attendance.find_by(user_id: user_id, attendance_event: attendance_event)
          if attendance
            attendance.update!(
              status: params[status_param],
              note: params[note_param] || ""
            )
            update_count += 1
          end
        end

        # セッションデータをクリア
        session.delete(:unchecked_attendance_data)

        render json: {
          success: true,
          message: "#{update_count}人の出席状況を更新しました",
          redirect_url: admin_attendance_path
        }
      end
    rescue => e
      render json: { 
        success: false, 
        message: "更新中にエラーが発生しました: #{e.message}" 
      }
    end
  end

  def update
    # パラメータから未チェックユーザー情報を取得
    unless params[:attendance_event_id] && params[:unchecked_user_ids]
      redirect_to admin_attendance_path, alert: "未チェックユーザー情報がありません。"
      return
    end
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    user_ids = params[:unchecked_user_ids].is_a?(Array) ? params[:unchecked_user_ids] : params[:unchecked_user_ids].to_s.split(',')
    @unchecked_users = User.where(id: user_ids).order(:generation, :name)
  end

  def save_update
    unless params[:attendance_event_id] && params[:unchecked_user_ids]
      redirect_to admin_attendance_path, alert: "未チェックユーザー情報がありません。"
      return
    end
    attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    user_ids = params[:unchecked_user_ids].is_a?(Array) ? params[:unchecked_user_ids] : params[:unchecked_user_ids].to_s.split(',')
    update_count = 0
    user_ids.each do |user_id|
      status_param = "status_#{user_id}"
      note_param = "note_#{user_id}"
      next unless params[status_param].present?
      attendance = Attendance.find_by(user_id: user_id, attendance_event: attendance_event)
      if attendance
        attendance.update!(
          status: params[status_param],
          note: params[note_param] || ""
        )
        update_count += 1
      end
    end
    redirect_to admin_attendance_path, notice: "#{update_count}人の出席状況を更新しました"
  end

  def status
    # 出欠受付管理画面用のデータを取得
    @attendance_events = AttendanceEvent.order(date: :desc)
    @competitions = Competition.order(date: :desc)
  end

  def update_status
    begin
      ActiveRecord::Base.transaction         # Strong Parametersで許可されたパラメータのみを取得
        permitted_attendance_events = attendance_events_params
        permitted_competitions = competitions_params

        # AttendanceEventの更新
        if permitted_attendance_events.present?
          permitted_attendance_events.each do |event_id, status|
            event = AttendanceEvent.find(event_id)
            event.update!(attendance_status: status)
          end
        end

        # Competitionの更新
        if permitted_competitions.present?
          permitted_competitions.each do |event_id, status|
            event = Competition.find(event_id)
            event.update!(attendance_status: status)
          end
        end

        if request.format.json? || request.content_type == 'application/json'
          render json: { success: true, message: "出欠受付状況を更新しました" }
        else
          redirect_to admin_attendance_status_path, notice: "出欠受付状況を更新しました"
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "AttendanceEvent/Competition not found in update_status: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      if request.format.json? || request.content_type == 'application/json'
        render json: { success: false, message: "指定されたイベントが見つかりません" }
      else
        redirect_to admin_attendance_status_path, alert: "指定されたイベントが見つかりません"
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation error in update_status: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      if request.format.json? || request.content_type == 'application/json'
        render json: { success: false, message: "データの検証に失敗しました: #{e.message}" }
      else
        redirect_to admin_attendance_status_path, alert: "データの検証に失敗しました: #{e.message}"
      end
    rescue => e
      Rails.logger.error "Unexpected error in update_status: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      
      if request.format.json? || request.content_type == 'application/json'
        render json: { success: false, message: "更新中にエラーが発生しました: #{e.message}" }
      else
        redirect_to admin_attendance_status_path, alert: "更新中にエラーが発生しました: #{e.message}"
      end
    end
  end

  private

  def attendance_events_params
    return {} unless params[:attendance_events].present?
    
    # 許可されたstatus値のみをフィルタリング
    permitted_statuses = AttendanceEvent.attendance_statuses.keys.map(&:to_s)
    
    params[:attendance_events].permit!.to_h.select do |event_id, status|
      permitted_statuses.include?(status.to_s)
    end
  end

  def competitions_params
    return {} unless params[:competitions].present?
    
    # 許可されたstatus値のみをフィルタリング
    permitted_statuses = Competition.attendance_statuses.keys.map(&:to_s)
    
    params[:competitions].permit!.to_h.select do |event_id, status|
      permitted_statuses.include?(status.to_s)
    end
  end
end 