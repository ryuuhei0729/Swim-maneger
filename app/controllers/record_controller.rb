class RecordController < ApplicationController
  def index
    @players = User.where(user_type: 'player').order(generation: :asc)
    @male_players = @players.select { |p| p.gender == 'male' }
    @female_players = @players.select { |p| p.gender == 'female' }
    @default_tab = params[:tab] || (current_user_auth.user.gender == 'male' ? 'male' : 'female')
    @sort_by = params[:sort_by]
    @sort_direction = params[:sort_direction] || 'asc'
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
      @players = sort_players_by_time(@players, @sort_by, @sort_direction)
      @male_players = sort_players_by_time(@male_players, @sort_by, @sort_direction)
      @female_players = sort_players_by_time(@female_players, @sort_by, @sort_direction)
    else
      # デフォルト表示用のグループ化
      @players_by_generation = @players.group_by(&:generation)
      @male_players_by_generation = @male_players.group_by(&:generation)
      @female_players_by_generation = @female_players.group_by(&:generation)
    end
  end

  private

  def sort_players_by_time(players, sort_by, direction)
    players.sort_by do |player|
      time = @best_times[player.id][sort_by]
      
      # タイムを秒数に変換
      if time.present?
        total_seconds = time.to_f
      else
        # タイムが無い場合は無限大として扱う
        total_seconds = Float::INFINITY
      end
      
      direction == 'asc' ? total_seconds : -total_seconds
    end
  end
end 