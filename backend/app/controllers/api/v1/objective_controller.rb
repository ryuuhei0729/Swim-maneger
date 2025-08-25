class Api::V1::ObjectiveController < Api::V1::BaseController
  def index
    objectives = current_user_auth.user.objectives
                                .includes(:attendance_event, :style, :milestones)
                                .order("events.date DESC")

    render_success({
      objectives: build_objectives_data(objectives),
      statistics: build_objectives_statistics(objectives)
    })
  end

  def create
    objective = current_user_auth.user.objectives.build(objective_params)

    # 目標タイムを秒に変換
    target_time = convert_time_to_seconds(params)
    objective.target_time = target_time if target_time

    if objective.save
      render_success({
        message: "目標を設定しました",
        objective: build_objective_data(objective)
      }, :created)
    else
      render_error("目標の設定に失敗しました", :unprocessable_entity, objective.errors)
    end
  end

  def show
    objective = current_user_auth.user.objectives
                               .includes(:attendance_event, :style, :milestones)
                               .find(params[:id])

    render_success({
      objective: build_objective_data(objective)
    })
  rescue ActiveRecord::RecordNotFound
    render_error("目標が見つかりません", :not_found)
  end

  def update
    objective = current_user_auth.user.objectives.find(params[:id])

    # 目標タイムを秒に変換
    target_time = convert_time_to_seconds(params)
    objective.target_time = target_time if target_time

    if objective.update(objective_params)
      render_success({
        message: "目標を更新しました",
        objective: build_objective_data(objective.reload)
      })
    else
      render_error("目標の更新に失敗しました", :unprocessable_entity, objective.errors)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("目標が見つかりません", :not_found)
  end

  def destroy
    objective = current_user_auth.user.objectives.find(params[:id])
    
    if objective.destroy
      render_success({
        message: "目標を削除しました"
      })
    else
      render_error("目標の削除に失敗しました", :unprocessable_entity)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("目標が見つかりません", :not_found)
  end

  private

  def build_objectives_data(objectives)
    objectives.map { |objective| build_objective_data(objective) }
  end

  def build_objective_data(objective)
    {
      id: objective.id,
      target_time: objective.target_time,
      formatted_target_time: format_swim_time(objective.target_time),
      target_time_minutes: (objective.target_time / 60).to_i,
      target_time_seconds: objective.target_time % 60,
      quantity_note: objective.quantity_note,
      quality_title: objective.quality_title,
      quality_note: objective.quality_note,
      attendance_event: {
        id: objective.attendance_event.id,
        title: objective.attendance_event.title,
        date: objective.attendance_event.date,
        place: objective.attendance_event.place,
        is_competition: objective.attendance_event.is_competition,
        formatted_date: objective.attendance_event.date.strftime("%Y年%m月%d日")
      },
      style: {
        id: objective.style.id,
        name: objective.style.name,
        name_jp: objective.style.name_jp,
        distance: objective.style.distance,
        style: objective.style.style,
        formatted_name: "#{objective.style.name_jp} (#{objective.style.distance}m)"
      },
      milestones: objective.milestones.map do |milestone|
        {
          id: milestone.id,
          milestone_type: milestone.milestone_type,
          milestone_type_label: milestone_type_label(milestone.milestone_type),
          limit_date: milestone.limit_date,
          formatted_limit_date: milestone.limit_date.strftime("%Y年%m月%d日"),
          note: milestone.note,
          is_overdue: milestone.limit_date < Date.current,
          days_remaining: (milestone.limit_date - Date.current).to_i,
          created_at: milestone.created_at,
          updated_at: milestone.updated_at
        }
      end.sort_by { |m| m[:limit_date] },
      created_at: objective.created_at,
      updated_at: objective.updated_at,
      days_until_event: (objective.attendance_event.date - Date.current).to_i,
      is_event_past: objective.attendance_event.date < Date.current
    }
  end

  def build_objectives_statistics(objectives)
    total_objectives = objectives.count
    active_objectives = objectives.joins(:attendance_event)
                                 .where("events.date >= ?", Date.current)
    past_objectives = objectives.joins(:attendance_event)
                                .where("events.date < ?", Date.current)
    
    milestones = Milestone.joins(:objective)
                         .where(objective: objectives)
    
    overdue_milestones = milestones.where("limit_date < ?", Date.current)
    upcoming_milestones = milestones.where("limit_date >= ? AND limit_date <= ?", 
                                          Date.current, 7.days.from_now)

    {
      total_objectives: total_objectives,
      active_objectives: active_objectives.count,
      past_objectives: past_objectives.count,
      total_milestones: milestones.count,
      overdue_milestones: overdue_milestones.count,
      upcoming_milestones: upcoming_milestones.count,
      styles_with_objectives: objectives.joins(:style).distinct.count(:style_id),
      upcoming_events: active_objectives.limit(3).map do |obj|
        {
          objective_id: obj.id,
          event_title: obj.attendance_event.title,
          event_date: obj.attendance_event.date,
          style_name: obj.style.name_jp,
          days_remaining: (obj.attendance_event.date - Date.current).to_i
        }
      end
    }
  end

  def milestone_type_label(milestone_type)
    case milestone_type
    when "quality"
      "質的目標"
    when "quantity"
      "量的目標"
    else
      "不明"
    end
  end

  def format_swim_time(time_in_seconds)
    return nil unless time_in_seconds
    
    minutes = (time_in_seconds / 60).to_i
    seconds = time_in_seconds % 60
    
    if minutes > 0
      "#{minutes}:#{sprintf('%05.2f', seconds)}"
    else
      sprintf('%.2f', seconds)
    end
  end

  def objective_params
    params.permit(
      :attendance_event_id,
      :style_id,
      :quantity_note,
      :quality_title,
      :quality_note,
      milestones_attributes: [ :milestone_type, :limit_date, :note ]
    )
  end

  # 分と秒から総秒数に変換するプライベートメソッド
  def convert_time_to_seconds(params)
    return nil unless params[:minutes].present? || params[:seconds].present?
    
    minutes = params[:minutes].to_i
    seconds = params[:seconds].to_f
    minutes * 60 + seconds
  end
end 