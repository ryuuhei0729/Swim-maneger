class RecordController < ApplicationController
  def index
    @practice_logs = PracticeLog.includes(:practice_times, :attendance_event)
                              .where(practice_times: { user_id: current_user_auth.user.id })
                              .order(created_at: :desc)
                              .page(params[:page])
                              .per(5)
  end

  def practice_times
    @practice_log = PracticeLog.find(params[:id])
    @practice_times = @practice_log.practice_times.where(user_id: current_user_auth.user.id)
                                 .order(set_number: :asc, rep_number: :asc)
    render partial: "practice_times_table", locals: { log: @practice_log, practice_times: @practice_times }
  end
end
