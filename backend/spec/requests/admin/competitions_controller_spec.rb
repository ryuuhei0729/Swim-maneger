require 'rails_helper'

RSpec.describe Admin::CompetitionsController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it '大会管理ページが表示される' do
      get admin_competition_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #start_entry_collection' do
    let!(:event) { create(:competition) }
    before { sign_in coach_auth }

    it 'エントリー受付が開始される' do
      post admin_start_entry_collection_path, params: { event_id: event.id }
      expect(response).to redirect_to(admin_competition_path)
      expect(flash[:notice]).to include('エントリー受付を開始しました')
    end
  end

  describe 'GET #show_entries' do
    let!(:event) { create(:competition) }
    before { sign_in coach_auth }

    it 'エントリー一覧がJSONで返される' do
      get admin_show_entries_path(competition_id: event.id), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end
  end
end 