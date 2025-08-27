require 'rails_helper'

RSpec.describe "Api::V1::Admin::Attendances", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/attendances" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user) { create(:user, :player) }
    let!(:attendance) { create(:attendance, user: user, attendance_event: attendance_event) }
    
    context "管理者の場合" do
      it "出欠管理データを返す" do
        get "/api/v1/admin/attendances", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['events']).to be_an(Array)
        expect(json['data']['users']).to be_an(Array)
        expect(json['data']['monthly_events']).to be_an(Array)
      end
      
      it "月指定で出欠データを取得できる" do
        get "/api/v1/admin/attendances", params: { month: "2025-01" }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['selected_month']).to eq("2025-01")
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/attendances", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/attendances/check" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user1) { create(:user, :player, name: "選手1") }
    let!(:user2) { create(:user, :player, name: "選手2") }
    let!(:attendance1) { create(:attendance, user: user1, attendance_event: attendance_event, status: 'present') }
    let!(:attendance2) { create(:attendance, user: user2, attendance_event: attendance_event, status: 'other', note: '体調不良のため欠席') }
    
    context "管理者の場合" do
      it "出席確認データを返す" do
        get "/api/v1/admin/attendances/check", 
            params: { attendance_event_id: attendance_event.id }, 
            headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['event']['id']).to eq(attendance_event.id)
        expect(json['data']['attendances'].count).to eq(2)
      end
    end
    
    context "イベントIDが提供されていない場合" do
      it "エラーを返す" do
        get "/api/v1/admin/attendances/check", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("イベントIDが必要です")
      end
    end
  end

  describe "PATCH /api/v1/admin/attendances/check" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user1) { create(:user, :player, name: "選手1") }
    let!(:user2) { create(:user, :player, name: "選手2") }
    let!(:attendance1) { create(:attendance, user: user1, attendance_event: attendance_event, status: 'present') }
    let!(:attendance2) { create(:attendance, user: user2, attendance_event: attendance_event, status: 'present') }
    
    context "一部のユーザーがチェックされていない場合" do
      it "未チェックユーザー情報を返す" do
        patch "/api/v1/admin/attendances/check", 
              params: { 
                attendance_event_id: attendance_event.id,
                checked_users: [user1.id] # user2はチェックされていない
              }, 
              headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['has_unchecked_users']).to be true
        expect(json['data']['unchecked_users'].count).to eq(1)
        expect(json['data']['unchecked_users'].first['name']).to eq("選手2")
      end
    end
    
    context "全員がチェックされている場合" do
      it "変更なしメッセージを返す" do
        patch "/api/v1/admin/attendances/check", 
              params: { 
                attendance_event_id: attendance_event.id,
                checked_users: [user1.id, user2.id]
              }, 
              headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['has_unchecked_users']).to be false
        expect(json['message']).to eq("全員が出席でした。変更はありません。")
      end
    end
  end

  describe "POST /api/v1/admin/attendances/save_check" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", date: Date.today) }
    let!(:user) { create(:user, :player, name: "選手1") }
    let!(:attendance) { create(:attendance, user: user, attendance_event: attendance_event, status: 'present') }
    
    let(:valid_updates) do
      {
        attendance_event_id: attendance_event.id,
        updates: [
          {
            user_id: user.id,
            status: 'absent',
            note: '病気のため欠席'
          }
        ]
      }
    end
    
    context "有効な更新データの場合" do
      it "出席状況を更新する" do
        post "/api/v1/admin/attendances/save_check", 
             params: valid_updates, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['updated_count']).to eq(1)
        expect(json['message']).to include("人の出席状況を更新しました")
        
        attendance.reload
        expect(attendance.status).to eq('absent')
        expect(attendance.note).to eq('病気のため欠席')
      end
    end
    
    context "必要なパラメータが不足している場合" do
      it "エラーを返す" do
        post "/api/v1/admin/attendances/save_check", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("必要なパラメータが不足しています")
      end
    end
  end

  describe "GET /api/v1/admin/attendances/status" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", attendance_status: :open) }
    let!(:competition) { create(:competition, title: "大会1", attendance_status: :before) }
    
    context "管理者の場合" do
      it "出欠受付状況データを返す" do
        get "/api/v1/admin/attendances/status", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['attendance_events']).to be_an(Array)
        expect(json['data']['competitions']).to be_an(Array)
        expect(json['data']['status_options']).to have_key('attendance_event_statuses')
        expect(json['data']['status_options']).to have_key('competition_statuses')
      end
    end
  end

  describe "PATCH /api/v1/admin/attendances/status" do
    let!(:attendance_event) { create(:attendance_event, title: "練習1", attendance_status: :before) }
    let!(:competition) { create(:competition, title: "大会1", attendance_status: :before) }
    
    let(:valid_updates) do
      {
        updates: {
          attendance_events: {
            attendance_event.id.to_s => 'open'
          },
          competitions: {
            competition.id.to_s => 'open'
          }
        }
      }
    end
    
    context "有効な更新データの場合" do
      it "出欠受付状況を更新する" do
        patch "/api/v1/admin/attendances/status", 
              params: valid_updates, 
              headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['updated_count']).to eq(2)
        expect(json['message']).to eq("出欠受付状況を更新しました")
        
        attendance_event.reload
        competition.reload
        expect(attendance_event.attendance_status).to eq('open')
        expect(competition.attendance_status).to eq('open')
      end
    end
    
    context "更新データが提供されていない場合" do
      it "エラーを返す" do
        patch "/api/v1/admin/attendances/status", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("更新データが必要です")
      end
    end
  end
end
