class Admin::ObjectivesController < Admin::BaseController
  def index
    @objectives = Objective.includes(:user, :attendance_event, :style, :milestones)
                         .order("attendance_events.date DESC")
  end
end 