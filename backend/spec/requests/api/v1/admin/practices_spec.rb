require 'rails_helper'

RSpec.describe "Api::V1::Admin::Practices", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/practices" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:practice_log) { create(:practice_log, attendance_event: attendance_event) }
    
    context "管理者の場合" do
      it "練習記録一覧を返す" do
        get "/api/v1/admin/practices", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['practice_logs']).to be_an(Array)
        expect(json['data']['total_count']).to be >= 1
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/practices", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/practices/:id" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:practice_log) { create(:practice_log, attendance_event: attendance_event) }
    let!(:user) { create(:user, :player) }
    let!(:practice_time) { create(:practice_time, practice_log: practice_log, user: user) }
    
    context "管理者の場合" do
      it "指定された練習記録を返す" do
        get "/api/v1/admin/practices/#{practice_log.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['practice_log']['id']).to eq(practice_log.id)
        expect(json['data']['practice_times_by_user']).to be_a(Hash)
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/practices/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("練習記録が見つかりません")
      end
    end
  end

  describe "GET /api/v1/admin/practices/time_setup" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    
    context "管理者の場合" do
      it "練習時間設定データを返す" do
        get "/api/v1/admin/practices/time_setup", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['attendance_events']).to be_an(Array)
        expect(json['data']['styles']).to be_a(Hash)
      end
    end
  end

  describe "POST /api/v1/admin/practices/time_preview" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user) { create(:user, :player) }
    let!(:attendance) { create(:attendance, user: user, attendance_event: attendance_event, status: 'present') }
    
    let(:valid_params) do
      {
        attendance_event_id: attendance_event.id,
        rep_count: 4,
        set_count: 2,
        circle: 90
      }
    end
    
    context "有効なパラメータの場合" do
      it "プレビューデータを返す" do
        post "/api/v1/admin/practices/time_preview", params: valid_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['practice_log']).to be_a(Hash)
        expect(json['data']['attendees']).to be_an(Array)
        expect(json['data']['attendees'].first['name']).to eq(user.name)
      end
    end
    
    context "無効なパラメータの場合" do
      it "エラーを返す" do
        invalid_params = valid_params.merge(rep_count: nil)
        
        post "/api/v1/admin/practices/time_preview", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("本数とセット数を入力してください")
      end
    end
  end

  describe "POST /api/v1/admin/practices/time_save" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user) { create(:user, :player) }
    
    let(:valid_params) do
      {
        practice_log: {
          attendance_event_id: attendance_event.id,
          style: "Fr",
          distance: 100,
          rep_count: 4,
          set_count: 2,
          circle: 90,
          note: "テスト練習"
        },
        times: {
          user.id.to_s => {
            "1" => {
              "1" => "60.50",
              "2" => "61.00"
            },
            "2" => {
              "1" => "59.80",
              "2" => "60.20"
            }
          }
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "練習記録とタイムを保存する" do
        expect {
          post "/api/v1/admin/practices/time_save", params: valid_params, headers: headers
        }.to change(PracticeLog, :count).by(1).and change(PracticeTime, :count).by(4)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("練習タイムとメニューを保存しました")
        expect(json['data']['times_count']).to eq(4)
      end
    end
  end

  describe "PATCH /api/v1/admin/practices/:id" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:practice_log) { create(:practice_log, attendance_event: attendance_event, note: "元のメモ") }
    
    let(:update_params) do
      {
        practice_log: {
          note: "更新されたメモ",
          distance: 200
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "練習記録を更新する" do
        patch "/api/v1/admin/practices/#{practice_log.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("練習記録を更新しました")
        
        practice_log.reload
        expect(practice_log.note).to eq("更新されたメモ")
        expect(practice_log.distance).to eq(200)
      end
    end
  end

  describe "DELETE /api/v1/admin/practices/:id" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:practice_log) { create(:practice_log, attendance_event: attendance_event) }
    
    context "管理者の場合" do
      it "練習記録を削除する" do
        expect {
          delete "/api/v1/admin/practices/#{practice_log.id}", headers: headers
        }.to change(PracticeLog, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("練習記録を削除しました")
      end
    end
  end

  describe "POST /api/v1/admin/practices/attendees" do
    let!(:user) { create(:user, :player) }
    
    context "参加者を追加する場合" do
      it "セッションに参加者を追加する" do
        post "/api/v1/admin/practices/attendees", 
             params: { action_type: 'add', attendee_id: user.id }, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['action']).to eq('add')
        expect(json['data']['attendee_id']).to eq(user.id)
      end
    end
    
    context "参加者を削除する場合" do
      it "セッションから参加者を削除する" do
        post "/api/v1/admin/practices/attendees", 
             params: { action_type: 'remove', attendee_id: user.id }, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['action']).to eq('remove')
        expect(json['data']['attendee_id']).to eq(user.id)
      end
    end
  end

  describe "GET /api/v1/admin/practices/register_setup" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    
    context "管理者の場合" do
      it "練習メニュー登録設定データを返す" do
        get "/api/v1/admin/practices/register_setup", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['attendance_events']).to be_an(Array)
      end
    end
  end

  describe "POST /api/v1/admin/practices/register" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let(:menu_image) { fixture_file_upload('files/test_image.jpg', 'image/jpeg') }
    
    context "有効なパラメータの場合" do
      it "練習メニュー画像を更新する" do
        post "/api/v1/admin/practices/register", 
             params: { 
               attendance_event_id: attendance_event.id,
               attendance_event: { menu_image: menu_image }
             }, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("練習メニュー画像を更新しました")
      end
    end
  end

  describe "GET /api/v1/admin/practices/attendees_list" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user) { create(:user, :player) }
    let!(:attendance) { create(:attendance, user: user, attendance_event: attendance_event, status: 'present') }
    
    context "管理者の場合" do
      it "参加者リストを返す" do
        get "/api/v1/admin/practices/attendees_list", 
            params: { event_id: attendance_event.id }, 
            headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['current_attendees']).to be_an(Array)
        expect(json['data']['available_for_add']).to be_an(Array)
      end
    end
  end
end
