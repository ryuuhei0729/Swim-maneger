class Admin::PracticesController < Admin::BaseController
  def index
    @practice_logs = PracticeLog.includes(attendance_event: { attendances: :user })
                               .order("events.date DESC")
                               .page(params[:page])
                               .per(20)
    
    # 各練習記録の参加者数を事前に計算（eager loadingで既にロード済み）
    @practice_logs.each do |log|
      # その日の出席者数を取得（presentまたはotherステータスの部員）
      attendees_count = log.attendance_event.attendances
                           .select { |attendance| 
                             ['present', 'other'].include?(attendance.status) && 
                             attendance.user.user_type == 'player' 
                           }
                           .count
      log.instance_variable_set(:@attendees_count, attendees_count)
    end
  end

  def show
    @practice_log = PracticeLog.includes(:attendance_event, practice_times: :user)
                               .find(params[:id])
    @practice_times_by_user = @practice_log.practice_times.group_by(&:user)
  end

  def edit
    @practice_log = PracticeLog.includes(:attendance_event, practice_times: :user)
                               .find(params[:id])
    @styles = PracticeLog::STYLE_OPTIONS
    @practice_times_by_user = @practice_log.practice_times.group_by(&:user)
  end

  def update
    @practice_log = PracticeLog.find(params[:id])
    
    PracticeLog.transaction do
      @practice_log.update!(practice_log_params)
      update_practice_times_for_log(@practice_log, params[:times]) if params[:times].present?
      redirect_to admin_practice_path, notice: "練習記録を更新しました。"
    rescue ActiveRecord::RecordInvalid => e
      prepare_edit_view
      flash.now[:alert] = "更新に失敗しました: #{@practice_log.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @practice_log = PracticeLog.find(params[:id])
    @practice_log.destroy
    redirect_to admin_practice_path, notice: "練習記録を削除しました。"
  end

  def time
    # 本日の日付を取得
    today = Date.today

    # 本日に最も近い練習を取得（過去の練習を優先）
    @attendance_events = AttendanceEvent.order(date: :desc)
    @default_event = @attendance_events.where("date <= ?", today).first || @attendance_events.first
    @styles = PracticeLog::STYLE_OPTIONS

    # GETパラメータから@practice_logを初期化
    @practice_log = PracticeLog.new(practice_log_get_params)

    # POSTリクエストの場合は新しい画面にリダイレクト
    if request.post?
      redirect_to admin_practice_time_input_path(practice_log: practice_log_params)
      return
    end
  end

  def time_input
    # パラメータから練習ログ情報を取得
    @practice_log = PracticeLog.new(practice_log_params)
    @styles = PracticeLog::STYLE_OPTIONS

    # パラメータがある場合はテーブルを生成
    if @practice_log.rep_count.present? && @practice_log.set_count.present?
      @laps = @practice_log.rep_count
      @sets = @practice_log.set_count

      # 選択された練習の参加者を取得
      event_id = @practice_log.attendance_event_id.presence || params.dig(:practice_log, :attendance_event_id).presence
      if event_id.present?
        @event = AttendanceEvent.find(event_id)
        @attendees = @event.attendances.includes(:user)
                          .where(status: [ "present", "other" ])
                          .joins(:user)
                          .where(users: { user_type: "player" })
                          .map(&:user)
                          .sort_by { |user| [ user.generation, user.name ] }
        
        # 削除された参加者を除外
        removed_attendee_ids = session[:removed_attendees] || []
        @attendees = @attendees.reject { |user| removed_attendee_ids.include?(user.id) }
        
        # 追加された参加者を取得
        additional_attendee_ids = session[:additional_attendees] || []
        if additional_attendee_ids.any?
          additional_attendees = User.where(id: additional_attendee_ids, user_type: 'player')
                                   .order(:generation, :name)
          @attendees = (@attendees + additional_attendees).uniq
        end
      end
    else
      redirect_to admin_practice_time_path, alert: "本数とセット数を入力してください"
    end
  end

  def create_time
    @practice_log = PracticeLog.new(practice_log_params)

    PracticeLog.transaction do
      @practice_log.save!
      create_practice_times_for_log(@practice_log, params[:times]) if params[:times].present?
      redirect_to admin_practice_path, notice: "練習タイムとメニューを保存しました。"
    rescue ActiveRecord::RecordInvalid => e
      prepare_time_view
      flash.now[:alert] = "保存に失敗しました: #{@practice_log.errors.full_messages.join(', ')}"
      render :time, status: :unprocessable_entity
    end
  end

  def register
    today = Date.today
    @attendance_events = AttendanceEvent.order(date: :desc)
    @default_event = @attendance_events.where("date <= ?", today).first || @attendance_events.first
    @attendance_event = AttendanceEvent.new
  end

  def create_register
    @attendance_event = AttendanceEvent.find(params[:attendance_event][:id])
    if @attendance_event.update(attendance_event_image_params)
      redirect_to admin_practice_path, notice: "練習メニュー画像を更新しました"
    else
      today = Date.today
      @attendance_events = AttendanceEvent.order(date: :desc)
      @default_event = @attendance_event
      render :register, status: :unprocessable_entity
    end
  end

  def add_attendee
    # 現在の参加者リストをセッションから取得
    session[:additional_attendees] ||= []
    
    # 新しい参加者IDを追加
    attendee_id = params[:attendee_id].to_i
    unless session[:additional_attendees].include?(attendee_id)
      session[:additional_attendees] << attendee_id
    end
    
    # 元の画面にリダイレクト
    redirect_back(fallback_location: admin_practice_time_input_path)
  end

  def remove_attendee
    # 参加者IDをセッションから削除
    session[:additional_attendees] ||= []
    attendee_id = params[:attendee_id].to_i
    session[:additional_attendees].delete(attendee_id)
    
    # 削除された参加者を記録（最初から出席していた参加者も削除可能にするため）
    session[:removed_attendees] ||= []
    session[:removed_attendees] << attendee_id unless session[:removed_attendees].include?(attendee_id)
    
    # 元の画面にリダイレクト
    redirect_back(fallback_location: admin_practice_time_input_path)
  end

  private

  def update_practice_times_for_log(practice_log, times_params)
    # 既存のタイムを削除
    practice_log.practice_times.destroy_all

    # 新しいタイムを保存
    create_practice_times_from_params(practice_log, times_params)
  end

  def create_practice_times_for_log(practice_log, times_params)
    create_practice_times_from_params(practice_log, times_params)
  end

  def create_practice_times_from_params(practice_log, times_params)
    times_params.each do |user_id, set_data|
      set_data.each do |set_number, rep_data|
        rep_data.each do |rep_number, time|
          next if time.blank?

          total_seconds = helpers.parse_time_to_seconds(time)

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

  def prepare_edit_view
    @styles = PracticeLog::STYLE_OPTIONS
    @practice_times_by_user = @practice_log.practice_times.group_by(&:user)
  end

  def prepare_time_view
    @styles = PracticeLog::STYLE_OPTIONS
    @attendance_events = AttendanceEvent.order(date: :desc)
    @default_event = @attendance_events.find_by(id: practice_log_params[:attendance_event_id]) || @attendance_events.first

    # モーダル再表示用パラメータ
    @laps = @practice_log.rep_count || 1
    @sets = @practice_log.set_count || 1
    @show_modal = true
    
    prepare_attendees_data if practice_log_params[:attendance_event_id].present?
  end

  def prepare_attendees_data
    @event = AttendanceEvent.find(practice_log_params[:attendance_event_id])
    @attendees = @event.attendances.includes(:user)
                      .where(status: ["present", "other"])
                      .joins(:user)
                      .where(users: { user_type: "player" })
                      .map(&:user)
                      .sort_by { |user| [user.generation, user.name] }
  end

  def practice_log_params
    params.require(:practice_log).permit(:attendance_event_id, :style, :rep_count, :set_count, :distance, :circle, :note)
  end

  def practice_log_get_params
    params.fetch(:practice_log, {}).permit(:attendance_event_id, :rep_count, :set_count, :circle)
  end

  def attendance_event_image_params
    params.require(:attendance_event).permit(:menu_image)
  end
end 