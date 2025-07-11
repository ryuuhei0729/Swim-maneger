class AdminController < ApplicationController
  before_action :authenticate_user_auth!
  before_action :check_admin_access

  def index
  end

  def create_user
    if request.post?
      @user = User.new(user_params)
      @user_auth = UserAuth.new(user_auth_params)

      User.transaction do
        if @user.save
          @user_auth.user = @user
          if @user_auth.save
            redirect_to admin_path, notice: "ユーザーを作成しました。"
          else
            @user.destroy
            if @user_auth.errors.any?
              @user_auth.errors.messages.each do |attribute, messages|
                messages.each do |message|
                  if message.is_a?(Symbol)
                    translated_message = I18n.t("errors.messages.#{message}", default: I18n.t("activerecord.errors.messages.#{message}", default: message))
                    @user.errors.add(attribute, translated_message)
                  else
                    @user.errors.add(attribute, message)
                  end
                end
              end
            end
            render :create_user, status: :unprocessable_entity
          end
        else
          render :create_user, status: :unprocessable_entity
        end
      end
    else
      @user = User.new
      @user_auth = UserAuth.new
    end
  end

  def announcement
    @announcements = Announcement.all.order(published_at: :desc)
    @announcement = Announcement.new
  end

  def create_announcement
    @announcement = Announcement.new(announcement_params)

    if @announcement.save
      redirect_to admin_announcement_path, notice: "お知らせを作成しました。"
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :announcement, status: :unprocessable_entity
    end
  end

  def update_announcement
    @announcement = Announcement.find(params[:id])

    if @announcement.update(announcement_params)
      redirect_to admin_announcement_path, notice: "お知らせを更新しました。"
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :announcement, status: :unprocessable_entity
    end
  end

  def destroy_announcement
    Rails.logger.info "destroy_announcement called with id: #{params[:id]}"
    @announcement = Announcement.find(params[:id])
    @announcement.destroy

    redirect_to admin_announcement_path, notice: "お知らせを削除しました。"
  end

  def schedule
    @events = AttendanceEvent.order(date: :asc)
    @event = AttendanceEvent.new
  end

  def create_schedule
    @event = AttendanceEvent.new(schedule_params)
    if @event.save
      redirect_to admin_schedule_path, notice: "スケジュールを登録しました。"
    else
      @events = AttendanceEvent.order(date: :asc)
      render :schedule, status: :unprocessable_entity
    end
  end

  def update_schedule
    @event = AttendanceEvent.find(params[:id])
    if @event.update(schedule_params)
      redirect_to admin_schedule_path, notice: "スケジュールを更新しました。"
    else
      @events = AttendanceEvent.order(date: :asc)
      render :schedule, status: :unprocessable_entity
    end
  end

  def destroy_schedule
    @event = AttendanceEvent.find(params[:id])
    @event.destroy
    redirect_to admin_schedule_path, notice: "スケジュールを削除しました。"
  end

  def edit_schedule
    @event = AttendanceEvent.find(params[:id])
    respond_to do |format|
      format.json { render json: {
        title: @event.title,
        date: @event.date.strftime("%Y-%m-%d"),
        is_competition: @event.is_competition,
        note: @event.note,
        place: @event.place
      }}
    end
  end

  def objective
    @objectives = Objective.includes(:user, :attendance_event, :style, :milestones)
                         .order("attendance_events.date DESC")
  end

  def practice_time
    # 本日の日付を取得
    today = Date.today

    # 本日に最も近い練習を取得（過去の練習を優先）
    @attendance_events = AttendanceEvent.order(date: :desc)
    @default_event = @attendance_events.where("date <= ?", today).first || @attendance_events.first
    @styles = PracticeLog::STYLE_OPTIONS

    # GETパラメータから@practice_logを初期化
    @practice_log = PracticeLog.new(practice_log_get_params)

    # パラメータがある場合はテーブルを生成
    if @practice_log.rep_count.present? && @practice_log.set_count.present?
      @laps = @practice_log.rep_count
      @sets = @practice_log.set_count
      @show_modal = true

      # 選択された練習の参加者を取得
      event_id = @practice_log.attendance_event_id.presence || params.dig(:practice_log, :attendance_event_id).presence || @default_event&.id
      if event_id.present?
        @event = AttendanceEvent.find(event_id)
        @attendees = @event.attendance.includes(:user)
                          .where(status: [ "present", "other" ])
                          .joins(:user)
                          .where(users: { user_type: "player" })
                          .map(&:user)
                          .sort_by { |user| [ user.generation, user.name ] }
      end
    end
  end

  def create_practice_log_and_times
    @practice_log = PracticeLog.new(practice_log_params)

    PracticeLog.transaction do
      @practice_log.save!

      times_params = params.require(:times)
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

            PracticeTime.create!(
              user_id: user_id,
              practice_log_id: @practice_log.id,
              set_number: set_number,
              rep_number: rep_number,
              time: total_seconds
            )
          end
        end
      end

      redirect_to admin_practice_path, notice: "練習タイムとメニューを保存しました。"
    rescue ActiveRecord::RecordInvalid => e
      # 失敗した場合、必要なインスタンス変数を再設定して元のページをレンダリング
      @styles = PracticeLog::STYLE_OPTIONS
      @attendance_events = AttendanceEvent.order(date: :desc)
      @default_event = @attendance_events.find_by(id: practice_log_params[:attendance_event_id]) || @attendance_events.first

      # モーダルを再表示するためのパラメータも設定
      @laps = @practice_log.rep_count || 1
      @sets = @practice_log.set_count || 1
      @show_modal = true
      if practice_log_params[:attendance_event_id].present?
        @event = AttendanceEvent.find(practice_log_params[:attendance_event_id])
        @attendees = @event.attendance.includes(:user)
                          .where(status: [ "present", "other" ])
                          .joins(:user)
                          .where(users: { user_type: "player" })
                          .map(&:user)
                          .sort_by { |user| [ user.generation, user.name ] }
      end

      flash.now[:alert] = "保存に失敗しました: #{@practice_log.errors.full_messages.join(', ')}"
      render :practice_time, status: :unprocessable_entity
    end
  end

  def practice
    @practice_logs = PracticeLog.includes(:attendance_event)
                               .order("attendance_events.date DESC")
                               .limit(5)
  end

  def attendance
    # 出欠管理画面用のデータを取得
    @events = AttendanceEvent.includes(:attendance)
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
      @selected_month = params[:month].present? ? Date.parse(params[:month]).beginning_of_month : Date.current.beginning_of_month
    rescue Date::Error
      @selected_month = Date.current.beginning_of_month
    end
    @monthly_events = AttendanceEvent.includes(:attendance)
                                   .where(date: @selected_month..@selected_month.end_of_month)
                                   .order(:date)
    
    # 月別の出欠データを整理
    @monthly_attendance_data = {}
    @users.each do |user|
      @monthly_attendance_data[user.id] = {}
      @monthly_events.each do |event|
        attendance = event.attendance.find_by(user: user)
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

  def attendance_check
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    # 「出席」「その他」で登録済みの人を取得
    @attendances = @attendance_event.attendance
                                  .includes(:user)
                                  .where(status: ['present', 'other'])
                                  .joins(:user)
                                  .where(users: { user_type: 'player' })
                                  .order('users.generation', 'users.name')
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_attendance_path, alert: "イベントが見つかりません"
  end

  def update_attendance_check
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    
    # デバッグログ
    Rails.logger.info "Received params: #{params.inspect}"
    Rails.logger.info "checked_users param: #{params[:checked_users]}"
    
    # 出席予定者の全ユーザーID
    all_present_user_ids = @attendance_event.attendance
                                           .where(status: ['present', 'other'])
                                           .joins(:user)
                                           .where(users: { user_type: 'player' })
                                           .pluck(:user_id)
    
    Rails.logger.info "All present user IDs: #{all_present_user_ids}"
    
    # チェックされたユーザーID
    checked_user_ids = params[:checked_users]&.keys&.map(&:to_i) || []
    
    Rails.logger.info "Checked user IDs: #{checked_user_ids}"
    
    # チェックされなかった（実際には出席していない）ユーザーID
    unchecked_user_ids = all_present_user_ids - checked_user_ids
    
    Rails.logger.info "Unchecked user IDs: #{unchecked_user_ids}"
    
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

  def save_attendance_check
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

  def practice_register
    today = Date.today
    @attendance_events = AttendanceEvent.order(date: :desc)
    @default_event = @attendance_events.where("date <= ?", today).first || @attendance_events.first
    @attendance_event = AttendanceEvent.new
  end

  def create_practice_register
    @attendance_event = AttendanceEvent.find(params[:attendance_event][:id])
    if @attendance_event.update(attendance_event_image_params)
      redirect_to admin_practice_path, notice: "練習メニュー画像を更新しました"
    else
      today = Date.today
      @attendance_events = AttendanceEvent.order(date: :desc)
      @default_event = @attendance_event
      render :practice_register, status: :unprocessable_entity
    end
  end

  def schedules_index
    # スケジュール一覧を取得する処理を追加予定
  end

  def attendance_update
    # パラメータから未チェックユーザー情報を取得
    unless params[:attendance_event_id] && params[:unchecked_user_ids]
      redirect_to admin_attendance_path, alert: "未チェックユーザー情報がありません。"
      return
    end
    @attendance_event = AttendanceEvent.find(params[:attendance_event_id])
    user_ids = params[:unchecked_user_ids].is_a?(Array) ? params[:unchecked_user_ids] : params[:unchecked_user_ids].to_s.split(',')
    @unchecked_users = User.where(id: user_ids).order(:generation, :name)
  end

  def save_attendance_update
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

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?([ "coach", "director" ])
      redirect_to root_path, alert: "このページにアクセスする権限がありません。"
    end
  end

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday)
  end

  def user_auth_params
    if params[:user_auth].present?
      params.require(:user_auth).permit(:email, :password, :password_confirmation)
    else
      # フォームからuser_authパラメータが送信されていない場合、userパラメータから取得
      params.require(:user).permit(:email, :password, :password_confirmation)
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
