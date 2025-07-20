require 'rails_helper'

RSpec.describe Admin::PracticesController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it '練習管理ページが表示される' do
      get admin_practice_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #time' do
    before { sign_in coach_auth }

    it '練習タイム管理ページが表示される' do
      get admin_practice_time_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_time' do
    let!(:event) { create(:attendance_event) }
    let!(:user) { create(:user, :player) }
    let!(:attendance) { create(:attendance, user: user, attendance_event: event, status: 'present') }
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          practice_log: {
            attendance_event_id: event.id,
            style: 'Fr',
            rep_count: 4,
            set_count: 2,
            distance: 100,
            circle: 120,
            note: 'テスト練習'
          },
          times: {
            user.id.to_s => {
              '1' => {
                '1' => '30.5',
                '2' => '31.2',
                '3' => '30.8',
                '4' => '31.0'
              },
              '2' => {
                '1' => '32.1',
                '2' => '31.8',
                '3' => '32.3',
                '4' => '31.9'
              }
            }
          }
        }
      end

      it '練習ログとタイムが作成される' do
        expect {
          post admin_create_practice_log_and_times_path, params: valid_params
        }.to change(PracticeLog, :count).by(1)
          .and change(PracticeTime, :count).by(8)

        expect(response).to redirect_to(admin_practice_path)
        expect(flash[:notice]).to eq('練習タイムとメニューを保存しました。')
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          practice_log: {
            attendance_event_id: event.id,
            style: '',
            rep_count: nil,
            set_count: nil,
            distance: 100,
            circle: 120,
            note: 'テスト練習'
          },
          times: {}
        }
      end

      it '練習ログが作成されず、エラーページが表示される' do
        expect {
          post admin_create_practice_log_and_times_path, params: invalid_params
        }.not_to change(PracticeLog, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #register' do
    before { sign_in coach_auth }

    it '練習登録ページが表示される' do
      get admin_practice_register_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_register' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          attendance_event: {
            id: event.id
          }
        }
      end

      it '練習メニュー画像が更新される' do
        post admin_practice_register_create_path, params: valid_params
        expect(response).to redirect_to(admin_practice_path)
        expect(flash[:notice]).to eq('練習メニュー画像を更新しました')
      end
    end
  end
end 