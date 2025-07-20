class Admin::CompetitionsController < Admin::BaseController
  def index
    # 大会一覧を取得（is_competitionがtrueのAttendanceEvent）
    @competitions = AttendanceEvent.where(is_competition: true)
                                 .order(date: :desc)
                                 .limit(10)
    
    # エントリー受付中の大会を取得
    @collecting_entries = AttendanceEvent.where(is_competition: true)
                                       .joins(:entries)
                                       .distinct
                                       .order(date: :desc)
  end

  def start_entry_collection
    @event = AttendanceEvent.find(params[:event_id])
    
    # 既にエントリー受付中かチェック（実際にはフラグ等で管理することもできますが、
    # 今回はエントリーが1件でもあれば受付中とします）
    
    redirect_to admin_competition_path, notice: "#{@event.title}のエントリー受付を開始しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません。"
  end

  def show_entries
    @event = AttendanceEvent.find(params[:event_id])
    @entries = @event.entries
                    .includes(:user, :style)
                    .order('users.generation, users.name, styles.style, styles.distance')
    
    # 種目別に集計
    @entries_by_style = @entries.group_by(&:style)
    
    respond_to do |format|
      format.json do
        render json: {
          event: {
            id: @event.id,
            title: @event.title,
            date: @event.date.strftime("%Y年%m月%d日")
          },
          entries: @entries.map do |entry|
            {
              id: entry.id,
              user_name: entry.user.name,
              user_generation: entry.user.generation,
              style_name: entry.style.name_jp,
              entry_time: entry.formatted_entry_time,
              note: entry.note
            }
          end,
          entries_by_style: @entries_by_style.transform_values do |style_entries|
            style_entries.map do |entry|
              {
                id: entry.id,
                user_name: entry.user.name,
                user_generation: entry.user.generation,
                entry_time: entry.formatted_entry_time,
                note: entry.note
              }
            end
          end
        }
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: { error: "大会が見つかりません" }, status: 404 }
    end
  end
end 