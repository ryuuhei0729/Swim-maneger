require 'rails_helper'

RSpec.describe Admin::SchedulesController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it 'スケジュール管理ページが表示される' do
      get admin_schedule_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          attendance_event: {
            title: 'テスト練習',
            date: Date.current + 1.day,
            event_type: 'AttendanceEvent',
            note: 'テストメモ',
            place: 'プール'
          }
        }
      end

      it 'スケジュールが作成される' do
        expect {
          post admin_create_schedule_path, params: valid_params
        }.to change(AttendanceEvent, :count).by(1)

        expect(response).to redirect_to(admin_schedule_path)
        expect(flash[:notice]).to eq('スケジュールを登録しました。')
      end
    end
  end

  describe 'PATCH #update' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          attendance_event: {
            title: '更新された練習',
            date: Date.current + 2.days,
            is_competition: false,
            note: '更新されたメモ',
            place: '更新されたプール'
          }
        }
      end

      it 'スケジュールが更新される' do
        patch admin_update_schedule_path(event), params: valid_params
        expect(response).to redirect_to(admin_schedule_path)
        expect(flash[:notice]).to eq('スケジュールを更新しました。')

        event.reload
        expect(event.title).to eq('更新された練習')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    it 'スケジュールが削除される' do
      expect {
        delete admin_destroy_schedule_path(event)
      }.to change(AttendanceEvent, :count).by(-1)

      expect(response).to redirect_to(admin_schedule_path)
      expect(flash[:notice]).to eq('スケジュールを削除しました。')
    end
  end

  describe 'GET #edit' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    it 'スケジュール編集用のJSONが返される' do
      get admin_edit_schedule_path(event), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['title']).to eq(event.title)
      expect(json_response['date']).to eq(event.date.strftime('%Y-%m-%d'))
      expect(json_response['type']).to eq(event.class.name)
      expect(json_response['note']).to eq(event.note)
      expect(json_response['place']).to eq(event.place)
    end
  end
end 