class HomeController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    start_time = Time.current
    
    # 現在の月を取得
    @current_month = if params[:month].present?
      begin
        Date.parse(params[:month])
      rescue ArgumentError => e
        Rails.logger.warn "Invalid date format in params[:month]: #{params[:month]}, error: #{e.message}"
        flash.now[:warning] = "無効な日付形式です。現在の月を表示します。"
        Date.current.beginning_of_month
      end
    else
      Date.current.beginning_of_month
    end

    # イベントを取得
    all_events = Event.where(date: @current_month.beginning_of_month..@current_month.end_of_month)
                     .order(:date, :created_at)

    # 誕生日ユーザーを取得
    @birthdays_by_date = {}
    User.all.each do |user|
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

    # ベストタイム取得の最適化（N+1問題の解決）
    @best_times = {}
    
    # キャッシュキーを生成（選手数と泳法数が変更された場合のみキャッシュを無効化）
    cache_key = "best_times_#{@players.count}_#{@events.count}_#{Record.maximum(:updated_at)&.to_i}"
    
    @best_times = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      best_times_hash = {}
      
      # 全選手のベストタイムを1回のクエリで取得
      best_records = Record.joins(:style, :user)
                          .where(users: { user_type: :player })
                          .select('records.*, styles.name as style_name, users.id as user_id')
                          .order('users.id, styles.name, records.time')
      
      # 選手IDと泳法名でグループ化してベストタイムを抽出
      best_records_by_user_and_style = {}
      best_records.each do |record|
        key = "#{record.user_id}_#{record.style_name}"
        best_records_by_user_and_style[key] = record.time unless best_records_by_user_and_style.key?(key)
      end
      
      # 結果をハッシュに格納
      @players.each do |player|
        best_times_hash[player.id] = {}
        @events.each do |event|
          key = "#{player.id}_#{event[:id]}"
          best_times_hash[player.id][event[:id]] = best_records_by_user_and_style[key]
        end
      end
      
      best_times_hash
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
    
    # パフォーマンスログ出力
    end_time = Time.current
    duration = (end_time - start_time) * 1000 # ミリ秒
    Rails.logger.info "Home#index 実行時間: #{duration.round(2)}ms"
  end

  private
  
  # キャッシュをクリアするメソッド
  def clear_best_times_cache
    Rails.cache.delete_matched("best_times_*")
  end
  
  def sort_players_by_time(players, sort_by)
    players.sort_by do |player|
      time = @best_times[player.id][sort_by]
      time.present? ? time.to_f : Float::INFINITY
    end
  end

  # 泳法別のCSSクラスを取得するヘルパーメソッド
  def style_header_class(style)
    case style
    when 'fr' then 'bg-header-freestyle'
    when 'br' then 'bg-header-breaststroke'
    when 'ba' then 'bg-header-backstroke'
    when 'fly' then 'bg-header-butterfly'
    when 'im' then 'bg-header-individual-medley'
    else 'bg-header-gray'
    end
  end

  def style_cell_class(style, is_current_user = false)
    return 'bg-current-user' if is_current_user
    
    case style
    when 'fr' then 'bg-freestyle-light'
    when 'br' then 'bg-breaststroke-light'
    when 'ba' then 'bg-backstroke-light'
    when 'fly' then 'bg-butterfly-light'
    when 'im' then 'bg-individual-medley-light'
    else 'bg-gray-default'
    end
  end

  helper_method :style_header_class, :style_cell_class
end
