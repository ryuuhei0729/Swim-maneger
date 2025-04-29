class RecordController < ApplicationController
  def index
    @players = User.where(user_type: 'player').order(generation: :desc)
    @players_by_generation = @players.group_by(&:generation)
    @male_players = @players.select { |p| p.gender == 'male' }
    @female_players = @players.select { |p| p.gender == 'female' }
    @male_players_by_generation = @male_players.group_by(&:generation)
    @female_players_by_generation = @female_players.group_by(&:generation)
    @default_tab = current_user_auth.user.gender == 'male' ? 'male' : 'female'
    @events = [
      { id: '50m_fr', title: '50m自由形', style: '自由形' },
      { id: '100m_fr', title: '100m自由形', style: '自由形' },
      { id: '200m_fr', title: '200m自由形', style: '自由形' },
      { id: '400m_fr', title: '400m自由形', style: '自由形' },
      { id: '800m_fr', title: '800m自由形', style: '自由形' },
      { id: '50m_br', title: '50m平泳ぎ', style: '平泳ぎ' },
      { id: '100m_br', title: '100m平泳ぎ', style: '平泳ぎ' },
      { id: '200m_br', title: '200m平泳ぎ', style: '平泳ぎ' },
      { id: '50m_ba', title: '50m背泳ぎ', style: '背泳ぎ' },
      { id: '100m_ba', title: '100m背泳ぎ', style: '背泳ぎ' },
      { id: '200m_ba', title: '200m背泳ぎ', style: '背泳ぎ' },
      { id: '50m_fly', title: '50mバタフライ', style: 'バタフライ' },
      { id: '100m_fly', title: '100mバタフライ', style: 'バタフライ' },
      { id: '200m_fly', title: '200mバタフライ', style: 'バタフライ' },
      { id: '100m_im', title: '100m個人メドレー', style: '個人メドレー' },
      { id: '200m_im', title: '200m個人メドレー', style: '個人メドレー' },
      { id: '400m_im', title: '400m個人メドレー', style: '個人メドレー' }
    ]
    @best_times = BestTimeTable.includes(:user)
  end
end 