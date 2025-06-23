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
        if @user.save && @user_auth.save
          @user_auth.update(user: @user)
          redirect_to admin_path, notice: "ユーザーを作成しました。"
        else
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
          render :create_user
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
      render :announcement
    end
  end

  def update_announcement
    @announcement = Announcement.find(params[:id])

    if @announcement.update(announcement_params)
      redirect_to admin_announcement_path, notice: "お知らせを更新しました。"
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :announcement
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
      render :schedule
    end
  end

  def update_schedule
    @event = AttendanceEvent.find(params[:id])
    if @event.update(schedule_params)
      redirect_to admin_schedule_path, notice: "スケジュールを更新しました。"
    else
      @events = AttendanceEvent.order(date: :asc)
      render :schedule
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
            
            # 時間を秒に変換
            minutes, seconds_milliseconds = time.split(':')
            seconds, milliseconds = seconds_milliseconds.split('.')
            total_seconds = minutes.to_i * 60 + seconds.to_i + milliseconds.to_f / 100

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
      @laps = @practice_log.rep_count
      @sets = @practice_log.set_count
      @show_modal = true
      if practice_log_params[:attendance_event_id].present?
        @event = AttendanceEvent.find(practice_log_params[:attendance_event_id])
        @attendees = @event.attendance.includes(:user)
                          .where(status: ["present", "other"])
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

  def practice_log
    @practice_log = PracticeLog.new
  end

  def create_practice_log
    @practice_log = PracticeLog.new(practice_log_params)

    if @practice_log.save
      redirect_to admin_practice_path, notice: "練習メニューを作成しました"
    else
      render :practice_log, status: :unprocessable_entity
    end
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

  def practice_log_params
    params.require(:practice_log).permit(:attendance_event_id, :style, :rep_count, :set_count, :distance, :circle, :note)
  end

  def practice_log_get_params
    params.fetch(:practice_log, {}).permit(:attendance_event_id, :style, :rep_count, :set_count, :distance, :circle, :note)
  end
end
