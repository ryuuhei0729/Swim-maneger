# require 'rails_helper'
# require 'stringio'

# RSpec.describe CalendarController, type: :request do
#   let(:user) { create(:user, :player) }
#   let(:user_auth) { create(:user_auth, user: user) }

#   describe '認証チェック' do
#     context '未ログインの場合' do
#       it 'カレンダー更新にアクセスするとログインページにリダイレクトされる' do
#         post calendar_update_path, params: { year: 2025, month: 6 }.to_json, headers: { 'Content-Type': 'application/json' }
#         expect(response).to redirect_to(new_user_auth_session_path)
#       end
#     end

#     context 'ログイン済みの場合' do
#       before { sign_in user_auth }

#              it 'カレンダー更新にアクセス可能' do
#          json_data = { year: 2025, month: 6 }.to_json
#          post calendar_update_path, 
#               headers: { 'CONTENT_TYPE' => 'application/json' },
#               env: { 'rack.input' => StringIO.new(json_data) }
#          expect(response).to have_http_status(:ok)
#        end
#     end
#   end

#   describe 'POST #update' do
#     let(:target_month) { Date.new(2025, 7, 1) }
#     let!(:attendance_event_in_month) { create(:attendance_event, date: target_month + 10.days) }
#     let!(:attendance_event_out_month) { create(:attendance_event, date: target_month + 2.months) }
#     let!(:event_in_month) { create(:event, date: target_month + 15.days) }
#     let!(:event_out_month) { create(:event, date: target_month - 1.month) }

#     before { sign_in user_auth }

#     context '有効なパラメータの場合' do
#       let(:valid_params) { { year: 2025, month: 7 } }

#       it 'カレンダーデータが正常に更新される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         expect(response).to have_http_status(:ok)
#         expect(response).to render_template(partial: 'shared/_calendar')
#       end

#       it '指定した月のcurrent_monthが設定される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         expect(assigns(:current_month)).to eq(target_month)
#       end

#       it '指定した月のAttendanceEventが取得される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         events_by_date = assigns(:events_by_date)
        
#         # 月内のイベントが含まれる
#         expect(events_by_date.values.flatten).to include(attendance_event_in_month)
#         # 月外のイベントは含まれない
#         expect(events_by_date.values.flatten).not_to include(attendance_event_out_month)
#       end

#       it '指定した月のEventが取得される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         events_by_date = assigns(:events_by_date)
        
#         # 月内のイベントが含まれる
#         expect(events_by_date.values.flatten).to include(event_in_month)
#         # 月外のイベントは含まれない
#         expect(events_by_date.values.flatten).not_to include(event_out_month)
#       end

#       it 'イベントが日付ごとにグループ化される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         events_by_date = assigns(:events_by_date)
        
#         # attendance_event_in_monthの日付にイベントが格納される
#         expect(events_by_date[attendance_event_in_month.date]).to include(attendance_event_in_month)
#         # event_in_monthの日付にイベントが格納される
#         expect(events_by_date[event_in_month.date]).to include(event_in_month)
#       end
#     end

#     context '誕生日データの取得' do
#       let!(:birthday_user) { create(:user, :player, birthday: Date.new(2000, 7, 20)) }
#       let!(:non_birthday_user) { create(:user, :player, birthday: Date.new(2000, 6, 15)) }
#       let(:valid_params) { { year: 2025, month: 7 } }

#       it 'その月に誕生日があるプレイヤーが取得される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
        
#         birthdays_by_date = assigns(:birthdays_by_date)
#         expected_birthday_date = Date.new(2025, 7, 20)
        
#         expect(birthdays_by_date[expected_birthday_date]).to include(birthday_user)
#       end

#       it '他の月に誕生日があるプレイヤーは取得されない' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
        
#         birthdays_by_date = assigns(:birthdays_by_date)
        
#         # 6月の誕生日なので7月には含まれない
#         expect(birthdays_by_date.values.flatten).not_to include(non_birthday_user)
#       end

#       it 'プレイヤー以外のユーザータイプは取得されない' do
#         coach_user = create(:user, :coach, birthday: Date.new(2000, 7, 25))
        
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
        
#         birthdays_by_date = assigns(:birthdays_by_date)
#         expect(birthdays_by_date.values.flatten).not_to include(coach_user)
#       end
#     end

#     context '複数のイベントが同じ日にある場合' do
#       let(:same_date) { target_month + 12.days }
#       let!(:attendance_event_same_day) { create(:attendance_event, date: same_date) }
#       let!(:event_same_day) { create(:event, date: same_date) }
#       let(:valid_params) { { year: 2025, month: 7 } }

#       it '同じ日のイベントが全て取得される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
        
#         events_by_date = assigns(:events_by_date)
#         same_day_events = events_by_date[same_date]
        
#         expect(same_day_events).to include(attendance_event_same_day)
#         expect(same_day_events).to include(event_same_day)
#       end

#       it 'Eventが先に追加される（表示順序の確認）' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
        
#         events_by_date = assigns(:events_by_date)
#         same_day_events = events_by_date[same_date]
        
#         # Eventが先にあることを確認（コメントの通り上に表示される）
#         event_index = same_day_events.index(event_same_day)
#         attendance_event_index = same_day_events.index(attendance_event_same_day)
        
#         expect(event_index).to be < attendance_event_index
#       end
#     end

#     context '無効なパラメータの場合' do
#       context 'yearパラメータが不正な場合' do
#         let(:invalid_params) { { year: 'invalid', month: 7 } }

#         it 'エラーが発生する' do
#           expect {
#             post calendar_update_path, params: invalid_params.to_json, headers: { 'Content-Type': 'application/json' }
#           }.to raise_error(ArgumentError)
#         end
#       end

#       context 'monthパラメータが不正な場合' do
#         let(:invalid_params) { { year: 2025, month: 'invalid' } }

#         it 'エラーが発生する' do
#           expect {
#             post calendar_update_path, params: invalid_params.to_json, headers: { 'Content-Type': 'application/json' }
#           }.to raise_error(ArgumentError)
#         end
#       end

#       context '存在しない月が指定された場合' do
#         let(:invalid_params) { { year: 2025, month: 13 } }

#         it 'エラーが発生する' do
#           expect {
#             post calendar_update_path, params: invalid_params.to_json, headers: { 'Content-Type': 'application/json' }
#           }.to raise_error(ArgumentError)
#         end
#       end
#     end

#     context 'リクエストヘッダーの確認' do
#       let(:valid_params) { { year: 2025, month: 7 } }

#       it 'JSON形式でのリクエストが正常に処理される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         expect(response).to have_http_status(:ok)
#       end

#       it 'HTMLレスポンスが返される' do
#         post calendar_update_path, params: valid_params.to_json, headers: { 'Content-Type': 'application/json' }
#         expect(response.content_type).to include('text/html')
#       end
#     end
#   end

#   describe 'コントローラーの継承' do
#     it 'ApplicationControllerを継承している' do
#       expect(CalendarController.superclass).to eq(ApplicationController)
#     end
#   end
# end 