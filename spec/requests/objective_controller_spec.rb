require 'rails_helper'

RSpec.describe ObjectiveController, type: :request do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:event) { create(:attendance_event) }
  let(:style) { create(:style, :freestyle, :distance_50) }

  describe '認証チェック' do
    context '未ログインの場合' do
      it '目標一覧にアクセスするとログイン画面にリダイレクトされる' do
        get objective_index_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end
    context 'ログイン済みの場合' do
      before { sign_in user_auth }
      it '目標一覧にアクセス可能' do
        get objective_index_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in user_auth }
    let!(:objective1) { create(:objective, user: user, attendance_event: event, style: style, target_time: 60.0) }
    let!(:objective2) { create(:objective, user: user, attendance_event: event, style: style, target_time: 70.0) }
    let!(:other_objective) { create(:objective) }

    it '自分の目標のみが表示される' do
      get objective_index_path
      objectives = assigns(:objective)
      expect(objectives).to include(objective1, objective2)
      expect(objectives).not_to include(other_objective)
    end

    it 'ページが正常に表示される' do
      get objective_index_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #new' do
    before { sign_in user_auth }
    it '新規作成画面が表示される' do
      get new_objective_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('目標')
    end
  end

  describe 'POST #create' do
    before { sign_in user_auth }
    let(:valid_params) do
      {
        objective: {
          attendance_event_id: event.id,
          style_id: style.id,
          quantity_note: '量の目標',
          quality_title: '質の目標タイトル',
          quality_note: '質の目標詳細',
          minutes: '1',
          seconds: '30.5'
        }
      }
    end

    it '有効なパラメータで目標を作成できる' do
      expect {
        post objective_index_path, params: valid_params
      }.to change(Objective, :count).by(1)
      expect(response).to redirect_to(objective_index_path)
      expect(flash[:notice]).to eq('目標を設定しました。')
      obj = Objective.last
      expect(obj.target_time).to eq(90.5)
      expect(obj.user).to eq(user)
    end

    it '無効なパラメータでは作成できずエラー表示' do
      expect {
        post objective_index_path, params: { objective: { attendance_event_id: nil, style_id: nil } }
      }.not_to change(Objective, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('目標')
    end

    it '目標タイムが未入力の場合はバリデーションエラーで作成できない' do
      params_without_time = { objective: valid_params[:objective].except(:minutes, :seconds) }
      expect {
        post objective_index_path, params: params_without_time
      }.not_to change(Objective, :count)
      
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('目標')
    end
  end
end
