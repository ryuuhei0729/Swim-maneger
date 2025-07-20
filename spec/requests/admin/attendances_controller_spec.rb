require 'rails_helper'

RSpec.describe Admin::AttendancesController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it '出欠管理ページが表示される' do
      get admin_attendance_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #check' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    it '出欠確認ページが表示される' do
      get admin_attendance_check_path(attendance_event_id: event.id)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #update' do
    let!(:event) { create(:attendance_event) }
    let!(:user) { create(:user, :player) }
    before { sign_in coach_auth }

    it '出欠更新ページが表示される' do
      get admin_attendance_update_path(attendance_event_id: event.id, unchecked_user_ids: [user.id])
      expect(response).to have_http_status(:ok)
    end
  end
end 