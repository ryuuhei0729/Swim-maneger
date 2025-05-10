class RecordController < ApplicationController
  def index
    @players = User.where(user_type: 'player').order(generation: :asc)
    @male_players = @players.select { |p| p.gender == 'male' }
    @female_players = @players.select { |p| p.gender == 'female' }
    @default_tab = params[:tab] || (current_user_auth.user.gender == 'male' ? 'male' : 'female')
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