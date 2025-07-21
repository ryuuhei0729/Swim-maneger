class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    # カレンダーの表示で使うコントローラー
    @current_month = Date.current

    # STI構造では全てのイベントをEventテーブルから取得
    all_events = Event
      .where(date: @current_month.beginning_of_month..@current_month.end_of_month)
      .order(date: :asc)

    # ログインユーザーの出席情報を取得
    @user_attendance_by_event = {}
    current_user_auth.user.attendance
      .joins(:attendance_event)
      .where(events: { date: @current_month.beginning_of_month..@current_month.end_of_month })
      .each do |attendance|
        @user_attendance_by_event[attendance.attendance_event_id] = attendance
      end

    # 誕生日データを取得
    @birthdays_by_date = {}
    User.where(user_type: :player).each do |user|
      # その月の誕生日を取得（年は考慮しない）
      next unless user.birthday.present?
      birthday_this_month = Date.new(@current_month.year, user.birthday.month, user.birthday.day)
      if birthday_this_month.month == @current_month.month
        @birthdays_by_date[birthday_this_month] ||= []
        @birthdays_by_date[birthday_this_month] << user
      end
    end

    # イベントを日付ごとにグループ化
    @events_by_date = {}
    all_events.each do |event|
      @events_by_date[event.date] ||= []
      @events_by_date[event.date] << event
    end

    # お知らせ表示で使うコントローラー
    @announcements = Announcement.active.where("published_at <= ?", Time.current).order(published_at: :desc)

    today = Date.current
    @birthday_users = User.where("EXTRACT(month FROM birthday) = ? AND EXTRACT(day FROM birthday) = ?", today.month, today.day)

    # ベストタイム表示で使うコントローラー
    @players = User.where(user_type: :player).order(generation: :asc)
    @male_players = @players.select { |p| p.male? }
    @female_players = @players.select { |p| p.female? }
    @default_tab = params[:tab] || (current_user_auth.user.male? ? "male" : "female")
    @sort_by = params[:sort_by]
    @events = Style.all.map do |style|
      {
        id: style.name,
        title: style.name_jp,
        style: style.style,
        distance: style.distance
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
