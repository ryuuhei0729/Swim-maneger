class Admin::ObjectivesController < Admin::BaseController
  def index
    @objectives = Objective.includes(:user, :attendance_event, :style, :milestones)
                         .order("events.date DESC")
  end
end 