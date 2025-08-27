class Api::V1::Admin::ObjectivesController < Api::V1::Admin::BaseController
  before_action :set_objective, only: [:show, :update, :destroy]

  # GET /api/v1/admin/objectives
  def index
    objectives = Objective.includes(:user, :attendance_event, :style, :milestones)
                         .joins(:attendance_event)
                         .order("objectives.created_at DESC")

    # フィルタリング
    objectives = filter_objectives(objectives)
    
    render_success({
      objectives: objectives.map { |objective| serialize_objective(objective) },
      total_count: objectives.count,
      statistics: calculate_statistics(objectives),
      filters: {
        users: User.where(user_type: 'player').order(:generation, :name).map { |u| { id: u.id, name: u.name } },
        events: Event.where(is_competition: true).order(date: :desc).map { |e| { id: e.id, title: e.title, date: e.date } },
        styles: Style.all.map { |s| { id: s.id, name_jp: s.name_jp } }
      }
    })
  end

  # GET /api/v1/admin/objectives/:id
  def show
    render_success({
      objective: serialize_objective_detail(@objective),
      milestones: @objective.milestones.order(:limit_date).map { |milestone| serialize_milestone(milestone) }
    })
  end

  # POST /api/v1/admin/objectives
  def create
    objective = Objective.new(objective_params)

    if objective.save
      # マイルストーンも同時に作成
      if params[:milestones].present?
        create_milestones(objective, params[:milestones])
      end

      render_success({
        objective: serialize_objective(objective)
      }, "目標を作成しました", :created)
    else
      render_error("目標の作成に失敗しました", :unprocessable_entity, objective.errors.as_json)
    end
  end

  # PATCH /api/v1/admin/objectives/:id
  def update
    Objective.transaction do
      @objective.update!(objective_params)

      # マイルストーンの更新
      if params[:milestones].present?
        update_milestones(@objective, params[:milestones])
      end

      render_success({
        objective: serialize_objective(@objective)
      }, "目標を更新しました")
    end
  rescue ActiveRecord::RecordInvalid => e
    render_error("目標の更新に失敗しました", :unprocessable_entity, @objective.errors.as_json)
  end

  # DELETE /api/v1/admin/objectives/:id
  def destroy
    @objective.destroy
    render_success({}, "目標を削除しました")
  end

  # GET /api/v1/admin/objectives/dashboard
  def dashboard
    # ダッシュボード用の統計データ
    total_objectives = Objective.count
    recent_objectives = Objective.where(created_at: 1.month.ago..Time.current).count
    
    # 達成状況の分析
    achievement_analysis = analyze_achievement_status
    
    # 期限切れの目標
    upcoming_deadlines = Objective.joins(:milestones)
                                 .where(milestones: { limit_date: Date.current..1.week.from_now })
                                 .distinct
                                 .includes(:user, :attendance_event, :style)

    render_success({
      statistics: {
        total_objectives: total_objectives,
        recent_objectives: recent_objectives,
        achievement_analysis: achievement_analysis
      },
      upcoming_deadlines: upcoming_deadlines.map { |obj| serialize_objective(obj) },
      recent_objectives: Objective.includes(:user, :attendance_event, :style)
                                 .order(created_at: :desc)
                                 .limit(5)
                                 .map { |obj| serialize_objective(obj) }
    })
  end

  # POST /api/v1/admin/objectives/:id/milestones
  def create_milestone
    set_objective
    milestone = @objective.milestones.build(milestone_params)

    if milestone.save
      render_success({
        milestone: serialize_milestone(milestone)
      }, "マイルストーンを作成しました", :created)
    else
      render_error("マイルストーンの作成に失敗しました", :unprocessable_entity, milestone.errors.as_json)
    end
  end

  # PATCH /api/v1/admin/objectives/milestones/:milestone_id
  def update_milestone
    milestone = Milestone.find(params[:milestone_id])

    if milestone.update(milestone_params)
      render_success({
        milestone: serialize_milestone(milestone)
      }, "マイルストーンを更新しました")
    else
      render_error("マイルストーンの更新に失敗しました", :unprocessable_entity, milestone.errors.as_json)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("マイルストーンが見つかりません", :not_found)
  end

  # DELETE /api/v1/admin/objectives/milestones/:milestone_id
  def destroy_milestone
    milestone = Milestone.find(params[:milestone_id])
    milestone.destroy

    render_success({}, "マイルストーンを削除しました")
  rescue ActiveRecord::RecordNotFound
    render_error("マイルストーンが見つかりません", :not_found)
  end

  # POST /api/v1/admin/objectives/milestones/:milestone_id/review
  def create_milestone_review
    milestone = Milestone.find(params[:milestone_id])
    review = milestone.milestone_reviews.build(milestone_review_params)

    if review.save
      render_success({
        review: serialize_milestone_review(review)
      }, "マイルストーンレビューを作成しました", :created)
    else
      render_error("レビューの作成に失敗しました", :unprocessable_entity, review.errors.as_json)
    end
  rescue ActiveRecord::RecordNotFound
    render_error("マイルストーンが見つかりません", :not_found)
  end

  private

  def set_objective
    @objective = Objective.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("目標が見つかりません", :not_found)
  end

  def objective_params
    params.require(:objective).permit(:user_id, :attendance_event_id, :style_id, :target_time, 
                                     :quantity_note, :quality_title, :quality_note)
  end

  def milestone_params
    params.require(:milestone).permit(:milestone_type, :limit_date, :note)
  end

  def milestone_review_params
    params.require(:milestone_review).permit(:achievement_rate, :negative_note, :positive_note)
  end

  def filter_objectives(objectives)
    objectives = objectives.where(user_id: params[:user_id]) if params[:user_id].present?
    objectives = objectives.where(attendance_event_id: params[:event_id]) if params[:event_id].present?
    objectives = objectives.where(style_id: params[:style_id]) if params[:style_id].present?
    
    if params[:date_from].present?
      objectives = objectives.joins(:attendance_event).where('attendance_events.date >= ?', params[:date_from])
    end
    
    if params[:date_to].present?
      objectives = objectives.joins(:attendance_event).where('attendance_events.date <= ?', params[:date_to])
    end
    
    objectives
  end

  def calculate_statistics(objectives)
    total = objectives.count
    with_milestones = objectives.joins(:milestones).distinct.count
    without_milestones = total - with_milestones
    
    {
      total_objectives: total,
      with_milestones: with_milestones,
      without_milestones: without_milestones,
      completion_rate: total > 0 ? (with_milestones.to_f / total * 100).round(1) : 0
    }
  end

  def analyze_achievement_status
    # マイルストーンレビューの達成率分析
    reviews = MilestoneReview.joins(milestone: :objective)
    
    if reviews.any?
      avg_achievement = reviews.average(:achievement_rate).round(1)
      high_achievement = reviews.where('achievement_rate >= 80').count
      medium_achievement = reviews.where('achievement_rate >= 50 AND achievement_rate < 80').count
      low_achievement = reviews.where('achievement_rate < 50').count
      
      {
        average_achievement_rate: avg_achievement,
        high_achievement_count: high_achievement,
        medium_achievement_count: medium_achievement,
        low_achievement_count: low_achievement,
        total_reviews: reviews.count
      }
    else
      {
        average_achievement_rate: 0,
        high_achievement_count: 0,
        medium_achievement_count: 0,
        low_achievement_count: 0,
        total_reviews: 0
      }
    end
  end

  def create_milestones(objective, milestones_params)
    milestones_params.each do |milestone_data|
      objective.milestones.create!(
        milestone_type: milestone_data[:milestone_type],
        limit_date: milestone_data[:limit_date],
        note: milestone_data[:note]
      )
    end
  end

  def update_milestones(objective, milestones_params)
    # 既存のマイルストーンを削除
    objective.milestones.destroy_all
    
    # 新しいマイルストーンを作成
    create_milestones(objective, milestones_params)
  end

  def serialize_objective(objective)
    {
      id: objective.id,
      user: {
        id: objective.user.id,
        name: objective.user.name,
        generation: objective.user.generation
      },
      event: {
        id: objective.attendance_event.id,
        title: objective.attendance_event.title,
        date: objective.attendance_event.date
      },
      style: {
        id: objective.style.id,
        name_jp: objective.style.name_jp,
        distance: objective.style.distance
      },
      target_time: objective.target_time,
      formatted_target_time: format_time(objective.target_time),
      quantity_note: objective.quantity_note,
      quality_title: objective.quality_title,
      quality_note: objective.quality_note,
      milestones_count: objective.milestones.count,
      created_at: objective.created_at,
      updated_at: objective.updated_at
    }
  end

  def serialize_objective_detail(objective)
    serialize_objective(objective).merge({
      latest_milestone_review: objective.milestones
                                       .joins(:milestone_reviews)
                                       .order('milestone_reviews.created_at DESC')
                                       .first&.milestone_reviews&.first&.then { |review| serialize_milestone_review(review) }
    })
  end

  def serialize_milestone(milestone)
    {
      id: milestone.id,
      objective_id: milestone.objective_id,
      milestone_type: milestone.milestone_type,
      milestone_type_label: milestone.milestone_type == 'quality' ? '質的目標' : '量的目標',
      limit_date: milestone.limit_date,
      note: milestone.note,
      reviews_count: milestone.milestone_reviews.count,
      latest_review: milestone.milestone_reviews.order(created_at: :desc).first&.then { |review| serialize_milestone_review(review) },
      created_at: milestone.created_at,
      updated_at: milestone.updated_at,
      is_overdue: milestone.limit_date < Date.current,
      days_until_deadline: (milestone.limit_date - Date.current).to_i
    }
  end

  def serialize_milestone_review(review)
    {
      id: review.id,
      milestone_id: review.milestone_id,
      achievement_rate: review.achievement_rate,
      negative_note: review.negative_note,
      positive_note: review.positive_note,
      created_at: review.created_at,
      updated_at: review.updated_at,
      achievement_level: case review.achievement_rate
                        when 0...50 then 'low'
                        when 50...80 then 'medium'
                        else 'high'
                        end
    }
  end

  def format_time(time_seconds)
    return "" if time_seconds.blank?
    
    minutes = (time_seconds / 60).to_i
    seconds = (time_seconds % 60)
    
    if minutes > 0
      format("%d:%05.2f", minutes, seconds)
    else
      format("%.2f", seconds)
    end
  end

end
