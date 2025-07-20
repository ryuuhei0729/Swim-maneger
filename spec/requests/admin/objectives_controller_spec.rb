require 'rails_helper'

RSpec.describe Admin::ObjectivesController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it '目標管理ページが表示される' do
      get admin_objective_path
      expect(response).to have_http_status(:ok)
    end
  end
end 