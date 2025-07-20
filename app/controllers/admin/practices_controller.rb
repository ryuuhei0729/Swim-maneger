class Admin::PracticesController < Admin::BaseController
  def index
    @practice_logs = PracticeLog.includes(:attendance_event)
                               .order("events.date DESC")
                               .limit(5)
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

    # パラメータがある場合はテーブルを生成
    if @practice_log.rep_count.present? && @practice_log.set_count.present?
      @laps = @practice_log.rep_count
      @sets = @practice_log.set_count
      @show_modal = true

      # 選択された練習の参加者を取得
      event_id = @practice_log.attendance_event_id.presence || params.dig(:practice_log, :attendance_event_id).presence || @default_event&.id
      if event_id.present?
        @event = AttendanceEvent.find(event_id)
        @attendees = @event.attendances.includes(:user)
                          .where(status: [ "present", "other" ])
                          .joins(:user)
                          .where(users: { user_type: "player" })
                          .map(&:user)
                          .sort_by { |user| [ user.generation, user.name ] }
      end
    end
  end

  def create_time
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
        @attendees = @event.attendances.includes(:user)
                          .where(status: [ "present", "other" ])
                          .joins(:user)
                          .where(users: { user_type: "player" })
                          .map(&:user)
                          .sort_by { |user| [ user.generation, user.name ] }
      end

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

  private

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