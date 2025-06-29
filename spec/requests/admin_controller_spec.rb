require 'rails_helper'

RSpec.describe AdminController, type: :request do
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
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('このページにアクセスする権限がありません。')
      end
    end

    context 'マネージャーでログインしている場合' do
      before { sign_in manager_auth }

      it '管理者ページにアクセスすると権限エラーでリダイレクトされる' do
        get admin_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('このページにアクセスする権限がありません。')
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

  describe 'GET #create_user' do
    before { sign_in coach_auth }

    it 'ユーザー作成ページが表示される' do
      get admin_create_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_user' do
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

  describe 'GET #announcement' do
    before { sign_in coach_auth }

    it 'お知らせ管理ページが表示される' do
      get admin_announcement_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_announcement' do
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

  describe 'PATCH #update_announcement' do
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

  describe 'DELETE #destroy_announcement' do
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

  describe 'GET #schedule' do
    before { sign_in coach_auth }

    it 'スケジュール管理ページが表示される' do
      get admin_schedule_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_schedule' do
    before { sign_in coach_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          attendance_event: {
            title: 'テスト練習',
            date: Date.current + 1.day,
            is_competition: false,
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

  describe 'PATCH #update_schedule' do
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

  describe 'DELETE #destroy_schedule' do
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

  describe 'GET #edit_schedule' do
    let!(:event) { create(:attendance_event) }
    before { sign_in coach_auth }

    it 'スケジュール編集用のJSONが返される' do
      get admin_edit_schedule_path(event), headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response['title']).to eq(event.title)
      expect(json_response['date']).to eq(event.date.strftime('%Y-%m-%d'))
      expect(json_response['is_competition']).to eq(event.is_competition)
      expect(json_response['note']).to eq(event.note)
      expect(json_response['place']).to eq(event.place)
    end
  end

  describe 'GET #objective' do
    before { sign_in coach_auth }

    it '目標管理ページが表示される' do
      get admin_objective_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #practice_time' do
    before { sign_in coach_auth }

    it '練習タイム管理ページが表示される' do
      get admin_practice_time_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_practice_log_and_times' do
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

  describe 'GET #practice' do
    before { sign_in coach_auth }

    it '練習管理ページが表示される' do
      get admin_practice_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #practice_register' do
    before { sign_in coach_auth }

    it '練習登録ページが表示される' do
      get admin_practice_register_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create_practice_register' do
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
