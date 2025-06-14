class ObjectiveController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @objective = current_user_auth.user.objectives
                                .includes(:attendance_event, :style, :milestones)
                                .order("attendance_events.date DESC")
  end

  def new
    @objective = current_user_auth.user.objectives.build
  end

  def create
    @objective = current_user_auth.user.objectives.build(objective_params)

    # 目標タイムを秒に変換
    if params[:objective][:minutes].present? || params[:objective][:seconds].present?
      minutes = params[:objective][:minutes].to_i
      seconds = params[:objective][:seconds].to_f
      @objective.target_time = minutes * 60 + seconds
    end

    if @objective.save
      redirect_to objective_index_path, notice: "目標を設定しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def objective_params
    params.require(:objective).permit(
      :attendance_event_id,
      :style_id,
      :quantity_note,
      :quality_title,
      :quality_note,
      milestones_attributes: [ :limit_date, :note ]
    )
  end
end
