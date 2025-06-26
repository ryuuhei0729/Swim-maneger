require 'rails_helper'

RSpec.describe UserAuths::SessionsController, type: :request do
  let(:user) { create(:user) }
  let(:user_auth) { create(:user_auth, user: user) }

  describe 'GET /user_auths/sign_in' do
    context '未ログインの場合' do
      it 'ログインページが表示される' do
        get new_user_auth_session_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('ログイン')
      end
    end

    context '既にログインしている場合' do
      before do
        sign_in user_auth
      end

      it 'ホームページにリダイレクトされる' do
        get new_user_auth_session_path
        expect(response).to redirect_to(home_path)
      end
    end
  end

  describe 'POST /user_auths/sign_in' do
    context '有効な認証情報の場合' do
      let(:valid_params) do
        {
          user_auth: {
            email: user_auth.email,
            password: '123123'
          }
        }
      end

      it 'ログインに成功し、ホームページにリダイレクトされる' do
        post user_auth_session_path, params: valid_params
        expect(response).to redirect_to(home_path)
        expect(flash[:needs_reload]).to be true
      end

      it 'ユーザーがログイン状態になる' do
        post user_auth_session_path, params: valid_params
        expect(controller.current_user_auth).to eq(user_auth)
      end
    end

    context '無効な認証情報の場合' do
      let(:invalid_params) do
        {
          user_auth: {
            email: user_auth.email,
            password: 'wrong_password'
          }
        }
      end

      it 'ログインに失敗し、ログインページに戻る' do
        post user_auth_session_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('ログイン')
      end

      it 'ユーザーがログイン状態にならない' do
        post user_auth_session_path, params: invalid_params
        expect(controller.current_user_auth).to be_nil
      end
    end

    context '存在しないメールアドレスの場合' do
      let(:non_existent_params) do
        {
          user_auth: {
            email: 'nonexistent@example.com',
            password: '123123'
          }
        }
      end

      it 'ログインに失敗し、ログインページに戻る' do
        post user_auth_session_path, params: non_existent_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('ログイン')
      end
    end

    context '空のパラメータの場合' do
      let(:empty_params) do
        {
          user_auth: {
            email: '',
            password: ''
          }
        }
      end

      it 'ログインに失敗し、ログインページに戻る' do
        post user_auth_session_path, params: empty_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('ログイン')
      end
    end
  end

  describe 'DELETE /user_auths/sign_out' do
    context 'ログインしている場合' do
      before do
        sign_in user_auth
      end

      it 'ログアウトに成功し、ログインページにリダイレクトされる' do
        delete destroy_user_auth_session_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end

      it 'ユーザーがログアウト状態になる' do
        delete destroy_user_auth_session_path
        expect(controller.current_user_auth).to be_nil
      end
    end

    context 'ログインしていない場合' do
      it 'ログインページにリダイレクトされる' do
        delete destroy_user_auth_session_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end
  end

  describe 'remember_me機能' do
    let(:remember_me_params) do
      {
        user_auth: {
          email: user_auth.email,
          password: '123123',
          remember_me: '1'
        }
      }
    end

    it 'remember_meパラメータが許可される' do
      post user_auth_session_path, params: remember_me_params
      expect(response).to redirect_to(home_path)
    end
  end

  describe 'セッション管理' do
    context 'ログイン後のセッション' do
      before do
        post user_auth_session_path, params: {
          user_auth: {
            email: user_auth.email,
            password: '123123'
          }
        }
      end

      it 'セッションが正しく設定される' do
        expect(controller.current_user_auth).to eq(user_auth)
        expect(controller.user_auth_signed_in?).to be true
      end
    end

    context 'ログアウト後のセッション' do
      before do
        sign_in user_auth
        sign_out user_auth
      end

      it '未ログイン状態で保護ページにアクセスするとログインページにリダイレクトされる' do
        get mypage_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end
  end
end 