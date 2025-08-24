require 'rails_helper'

RSpec.describe Admin::AnnouncementsController, type: :request do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe 'GET #index' do
    before { sign_in coach_auth }

    it 'お知らせ管理ページが表示される' do
      get admin_announcement_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          announcement: {
            title: 'テストお知らせ',
            content: 'テスト内容',
            is_active: true,
            published_at: 1.day.from_now
          }
        }
      end

      it 'お知らせが作成される' do
        expect {
          post admin_announcement_path, params: valid_params
        }.to change(Announcement, :count).by(1)

        expect(response).to redirect_to(admin_announcement_path)
        expect(flash[:notice]).to eq('お知らせを作成しました。')
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) do
        {
          announcement: {
            title: '',
            content: '',
            is_active: true,
            published_at: 1.day.from_now
          }
        }
      end

      it 'お知らせが作成されず、エラーページが表示される' do
        expect {
          post admin_announcement_path, params: invalid_params
        }.not_to change(Announcement, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH #update' do
    let!(:announcement) { create(:announcement) }
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          announcement: {
            title: '更新されたお知らせ',
            content: '更新された内容',
            is_active: true,
            published_at: 1.hour.from_now
          }
        }
      end

      it 'お知らせが更新される' do
        patch admin_update_announcement_path(announcement), params: valid_params
        expect(response).to redirect_to(admin_announcement_path)
        expect(flash[:notice]).to eq('お知らせを更新しました。')

        announcement.reload
        expect(announcement.title).to eq('更新されたお知らせ')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:announcement) { create(:announcement) }
    before { sign_in coach_auth }

    it 'お知らせが削除される' do
      expect {
        delete admin_destroy_announcement_path(announcement)
      }.to change(Announcement, :count).by(-1)

      expect(response).to redirect_to(admin_announcement_path)
      expect(flash[:notice]).to eq('お知らせを削除しました。')
    end
  end
end 