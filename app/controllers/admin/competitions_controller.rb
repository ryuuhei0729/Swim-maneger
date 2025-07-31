class Admin::CompetitionsController < Admin::BaseController
  def index
    # 大会一覧を取得（STI構造を活用）
    @competitions = Competition.order(date: :desc).limit(10)
    
    # エントリー受付中の大会を取得
    @collecting_entries = Competition.joins(:entries)
                                   .distinct
                                   .order(date: :desc)
  end

  def update_entry_status
    @competition = Competition.find(params[:id])
    
    # JSONパラメータからentry_statusを取得
    entry_status = params[:entry_status] || request.body.read
    
    if @competition.update(entry_status: entry_status)
      render json: { success: true, message: "エントリー受付状況を更新しました" }
    else
      render json: { success: false, message: "更新に失敗しました" }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: "大会が見つかりません" }
  end

  def result
    @competition = Competition.find(params[:id])
    # 結果入力画面用のデータを取得
    @entries = @competition.entries.includes(:user, :style).order('users.generation', 'users.name')
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません"
  end

  def start_entry_collection
    @event = Competition.find(params[:event_id])
    
    # 既にエントリー受付中かチェック（実際にはフラグ等で管理することもできますが、
    # 今回はエントリーが1件でもあれば受付中とします）
    
    redirect_to admin_competition_path, notice: "#{@event.title}のエントリー受付を開始しました。"
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_competition_path, alert: "大会が見つかりません。"
  end

  def show_entries
    @event = Competition.find(params[:event_id])
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
                note: entry.note,
                style_name: entry.style&.name_jp
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