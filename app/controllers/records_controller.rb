class RecordsController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @records = @user.records.includes(:style, :attendance_event).order(created_at: :desc)

    # 大会ごとに記録をグルーピング
    @records_by_event = @records.group_by(&:attendance_event)
                               .sort_by { |event, records| 
                                 if event.present?
                                   event.date
                                 else
                                   records.first.created_at
                                 end
                               }
                               .reverse

    # 各種目のベストタイムを取得
    @best_times = {}
    Style.all.each do |style|
      best_record = @user.records
        .joins(:style)
        .where(styles: { name: style.name })
        .order(:time)
        .first
      @best_times[style.name] = best_record&.time
    end
    
    # ベストタイムのnoteを取得
    @best_time_notes = @user.best_time_notes
  end

  private

  def format_time_display(seconds)
    return "-" if seconds.nil? || seconds.zero?

    minutes = (seconds / 60).floor
    remaining_seconds = (seconds % 60).round(2)

    if minutes.zero?
      sprintf("%05.2f", remaining_seconds)
    else
      sprintf("%d:%05.2f", minutes, remaining_seconds)
    end
  end
  
  helper_method :format_time_display
end 