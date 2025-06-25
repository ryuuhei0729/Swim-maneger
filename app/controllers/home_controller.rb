class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    # カレンダーの表示で使うコントローラー
    @current_month = Date.current
    
    attendance_events = AttendanceEvent
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
    
    events = Event
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)
    
    # 両方のイベントを日付ごとにグループ化してマージ
    @events_by_date = {}
    
    # Eventを先に追加（上に表示される）
    events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end
    
    # AttendanceEventを後から追加（下に表示される）
    attendance_events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end

    # お知らせ表示で使うコントローラー
    @announcements = Announcement.active.where("published_at <= ?", Time.current).order(published_at: :desc)

    today = Date.current
    @birthday_users = User.where(birthday: today)

    # ベストタイム表示で使うコントローラー
    @players = User.where(user_type: "player").order(generation: :asc)
    @male_players = @players.select { |p| p.gender == "male" }
    @female_players = @players.select { |p| p.gender == "female" }
    @default_tab = params[:tab] || (current_user_auth.user.gender == "male" ? "male" : "female")
    @sort_by = params[:sort_by]
    @events = Style.all.map do |style|
      {
        id: style.name,
        title: style.name_jp,
        style: style.style
      }
    end

    # 各選手のベストタイムを取得
    @best_times = {}
    @players.each do |player|
      @best_times[player.id] = {}
      @events.each do |event|
        best_record = player.records
          .joins(:style)
          .where(styles: { name: event[:id] })
          .order(:time)
          .first
        @best_times[player.id][event[:id]] = best_record&.time
      end
    end

    # 並び替え処理
    if @sort_by.present?
      @players = sort_players_by_time(@players, @sort_by)
      @male_players = sort_players_by_time(@male_players, @sort_by)
      @female_players = sort_players_by_time(@female_players, @sort_by)
    else
      # デフォルト表示用のグループ化
      @players_by_generation = @players.group_by(&:generation)
      @male_players_by_generation = @male_players.group_by(&:generation)
      @female_players_by_generation = @female_players.group_by(&:generation)
    end
  end

  private
  def sort_players_by_time(players, sort_by)
    players.sort_by do |player|
      time = @best_times[player.id][sort_by]
      time.present? ? time.to_f : Float::INFINITY
    end
  end
end
