require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #create' do
    before { sign_in coach_auth }

    it 'ユーザー作成ページが表示される' do
      get admin_create_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          user: {
            name: 'テストユーザー',
            user_type: 'player',
            generation: 90,
            gender: 'male',
            birthday: '2000-01-01',
            email: 'test@example.com',
            password: '123123',
            password_confirmation: '123123'
          }
        }
      end

      it 'ユーザーが作成される' do
        expect {
          post admin_users_path, params: valid_params
        }.to change(User, :count).by(1)
          .and change(UserAuth, :count).by(1)

        expect(response).to redirect_to(admin_path)
        expect(flash[:notice]).to eq('ユーザーを作成しました。')
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          user: {
            name: '',
            user_type: 'player',
            generation: 90,
            gender: 'male',
            birthday: '2000-01-01',
            email: 'invalid-email',
            password: '123123',
            password_confirmation: '123123'
          }
        }
      end

      it 'ユーザーが作成されず、エラーページが表示される' do
        expect {
          post admin_users_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end 