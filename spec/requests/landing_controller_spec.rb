require 'rails_helper'

RSpec.describe LandingController, type: :request do
  describe 'GET #index' do
    context '未ログインの場合' do
      it 'ランディングページにアクセス可能' do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it 'ログイン画面へのリンクが表示される' do
        get root_path
        expect(response.body).to include('ログイン画面へ')
      end
    end

    context 'ログイン済みの場合' do
      let(:user) { create(:user, :player) }
      let(:user_auth) { create(:user_auth, user: user) }

      before { sign_in user_auth }

      it 'ランディングページにアクセス可能' do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
