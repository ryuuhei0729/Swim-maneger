require 'rails_helper'

RSpec.describe AttendanceController, type: :request do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe '認証チェック' do
    context '未ログインの場合' do
      it '出席管理画面にアクセスするとログインページにリダイレクトされる' do
        get attendance_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before { sign_in user_auth }

      it '出席管理画面にアクセス可能' do
        get attendance_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    let!(:current_month_event) { create(:attendance_event, date: Date.current + 15.days, attendance_status: :open) }
    let!(:next_month_event) { create(:attendance_event, date: Date.current.next_month.beginning_of_month + 10.days, attendance_status: :open) }
    let!(:past_event) { create(:attendance_event, date: Date.current - 5.days, attendance_status: :open) }

    before { sign_in user_auth }

    context 'monthパラメータなしの場合' do
      it '今月のデータが表示される' do
        get attendance_path
        expect(response).to have_http_status(:ok)
        expect(assigns(:current_month)).to eq(Date.current)
      end

      it '今月と来月のイベントが取得される' do
        get attendance_path
        expect(assigns(:open_events)).to include(current_month_event)
        expect(assigns(:open_events)).to include(next_month_event)
      end

      it '過去のイベントは取得されない' do
        get attendance_path
        expect(assigns(:open_events)).not_to include(past_event)
      end
    end

    context 'monthパラメータありの場合' do
      let(:target_month) { Date.current.next_month }

      it '指定した月のデータが表示される' do
        get attendance_path, params: { month: target_month.strftime('%Y-%m-%d') }
        expect(response).to have_http_status(:ok)
        expect(assigns(:current_month)).to eq(target_month)
      end
    end

    context '既に回答済みのイベントがある場合' do
      let!(:answered_attendance) do
        create(:attendance, user: user, attendance_event: current_month_event, status: 'present')
      end

      it '回答済みのイベントは未回答イベントリストに含まれない' do
        get attendance_path
        expect(assigns(:open_events)).not_to include(current_month_event)
      end
    end

    context 'Ajax リクエストの場合' do
      it 'カレンダーのpartialがレンダリングされる' do
        get attendance_path, xhr: true
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(partial: 'shared/_calendar')
      end
    end

    context '誕生日データの取得' do
      let!(:birthday_user) do
        create(:user, :player, birthday: Date.new(2000, Date.current.month, 15))
      end

      it 'その月に誕生日があるプレイヤーが取得される' do
        get attendance_path
        expect(assigns(:birthdays_by_date)).to have_key(Date.new(Date.current.year, Date.current.month, 15))
        expect(assigns(:birthdays_by_date)[Date.new(Date.current.year, Date.current.month, 15)]).to include(birthday_user)
      end
    end
  end

  describe 'POST #update_attendance' do
    let!(:event1) { create(:attendance_event, date: Date.current + 1.day, attendance_status: :open) }
    let!(:event2) { create(:attendance_event, date: Date.current + 2.days, attendance_status: :open) }

    before { sign_in user_auth }

    context '有効なパラメータの場合' do
      let(:valid_params) do
        {
          attendance: {
            event1.id.to_s => {
              status: 'present',
              note: ''
            },
            event2.id.to_s => {
              status: 'absent',
              note: '体調不良のため'
            }
          }
        }
      end

      it '出席状況が正常に更新される' do
        expect {
          post update_attendance_path, params: valid_params
        }.to change(Attendance, :count).by(2)

        expect(response).to redirect_to(attendance_path)
        expect(flash[:notice]).to eq('出席状況を更新しました。')
      end

      it '出席記録が正しく作成される' do
        post update_attendance_path, params: valid_params

        attendance1 = user.attendance.find_by(attendance_event: event1)
        attendance2 = user.attendance.find_by(attendance_event: event2)

        expect(attendance1.status).to eq('present')
        expect(attendance2.status).to eq('absent')
        expect(attendance2.note).to eq('体調不良のため')
      end
    end

    context '既存の出席記録を更新する場合' do
      let!(:existing_attendance) do
        create(:attendance, user: user, attendance_event: event1, status: 'absent', note: '最初の理由')
      end

      let(:update_params) do
        {
          attendance: {
            event1.id.to_s => {
              status: 'present',
              note: ''
            }
          }
        }
      end

      it '既存の出席記録が更新される' do
        expect {
          post update_attendance_path, params: update_params
        }.not_to change(Attendance, :count)

        existing_attendance.reload
        expect(existing_attendance.status).to eq('present')
        expect(existing_attendance.note).to eq('')
      end
    end

    context '無効なパラメータの場合' do
      context 'ステータスが空の場合' do
        let(:invalid_params) do
          {
            attendance: {
              event1.id.to_s => {
                status: '',
                note: ''
              }
            }
          }
        end

        it 'エラーメッセージが表示される' do
          post update_attendance_path, params: invalid_params
          expect(response).to redirect_to(attendance_path)
          expect(flash[:alert]).to include('の出席状況を選択してください')
        end

        it '出席記録が作成されない' do
          expect {
            post update_attendance_path, params: invalid_params
          }.not_to change(Attendance, :count)
        end
      end

      context '欠席時に備考が空の場合' do
        let(:invalid_params) do
          {
            attendance: {
              event1.id.to_s => {
                status: 'absent',
                note: ''
              }
            }
          }
        end

        it 'エラーメッセージが表示される' do
          post update_attendance_path, params: invalid_params
          expect(response).to redirect_to(attendance_path)
          expect(flash[:alert]).to include('の備考を入力してください')
        end
      end

      context '遅刻時に備考が空の場合' do
        let(:invalid_params) do
          {
            attendance: {
              event1.id.to_s => {
                status: 'late',
                note: ''
              }
            }
          }
        end

        it 'エラーメッセージが表示される' do
          post update_attendance_path, params: invalid_params
          expect(response).to redirect_to(attendance_path)
          expect(flash[:alert]).to include('の備考を入力してください')
        end
      end
    end

    context '複数のエラーがある場合' do
      let(:multiple_error_params) do
        {
          attendance: {
            event1.id.to_s => {
              status: '',
              note: ''
            },
            event2.id.to_s => {
              status: 'absent',
              note: ''
            }
          }
        }
      end

      it '複数のエラーメッセージが表示される' do
        post update_attendance_path, params: multiple_error_params
        expect(response).to redirect_to(attendance_path)
        expect(flash[:alert]).to include('の出席状況を選択してください')
        expect(flash[:alert]).to include('の備考を入力してください')
      end
    end
  end

  describe 'GET #event_status' do
    let!(:event) { create(:attendance_event) }
    let!(:attendance1) { create(:attendance, attendance_event: event, status: 'present') }
    let!(:attendance2) { create(:attendance, attendance_event: event, status: 'absent', note: '体調不良') }

    before { sign_in user_auth }

    it '指定したイベントの出席状況が取得される' do
      get event_status_path(event_id: event.id)
      expect(response).to have_http_status(:ok)
      expect(assigns(:event)).to eq(event)
      expect(assigns(:attendance)).to include(attendance1, attendance2)
    end

    it 'event_attendance_statusのpartialがレンダリングされる' do
      get event_status_path(event_id: event.id)
      expect(response).to render_template(partial: 'shared/_event_attendance_status')
    end

    context '存在しないイベントIDの場合' do
      it '404エラーが返される' do
        get event_status_path(event_id: 999999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'コントローラーの継承' do
    it 'ApplicationControllerを継承している' do
      expect(AttendanceController.superclass).to eq(ApplicationController)
    end

    it 'authenticate_user_auth!が設定されている' do
      expect(AttendanceController._process_action_callbacks.map(&:filter)).to include(:authenticate_user_auth!)
    end
  end
end 