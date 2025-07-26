require 'rails_helper'

RSpec.describe Admin::BaseController, type: :request do
  let(:player_user) { create(:user, :player) }
  let(:coach_user) { create(:user, :coach) }
  let(:director_user) { create(:user, :director) }
  let(:manager_user) { create(:user, :manager) }

  let(:player_auth) { create(:user_auth, user: player_user) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }
  let(:director_auth) { create(:user_auth, user: director_user) }
  let(:manager_auth) { create(:user_auth, user: manager_user) }

  describe '認証と権限チェック' do
    context '未ログインの場合' do
      it '管理者ページにアクセスするとログインページにリダイレクトされる' do
        get admin_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end

    context 'プレイヤーでログインしている場合' do
      before { sign_in player_auth }

      it '管理者ページにアクセスすると権限エラーでリダイレクトされる' do
        get admin_path
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq('このページにアクセスする権限がありません。')
      end
    end

    context 'マネージャーでログインしている場合' do
      before { sign_in manager_auth }

      it '管理者ページにアクセス可能' do
        get admin_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'コーチでログインしている場合' do
      before { sign_in coach_auth }

      it '管理者ページにアクセス可能' do
        get admin_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'ディレクターでログインしている場合' do
      before { sign_in director_auth }

      it '管理者ページにアクセス可能' do
        get admin_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in coach_auth }

    it '管理者ダッシュボードページが表示される' do
      get admin_path
      expect(response).to have_http_status(:ok)
    end
  end
end 