require 'rails_helper'

RSpec.describe "Api::V1::Admin::Dashboard", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { auth_headers(admin_user_auth) }
  let(:player_headers) { auth_headers(player_user_auth) }

  describe "GET /api/v1/admin/dashboard" do
    let!(:player) { create(:user, :player) }
    let!(:announcement) { create(:announcement, is_active: true) }
    let!(:attendance_event) { create(:attendance_event, date: Date.current + 1.week) }
    
    context "管理者の場合" do
      it "ダッシュボードデータを返す" do
        get "/api/v1/admin/dashboard", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("管理者ダッシュボードデータを取得しました")
        
        # データ構造の確認
        expect(json['data']).to have_key('summary')
        expect(json['data']).to have_key('recent_activities')
        expect(json['data']).to have_key('quick_stats')
        
        # summary の確認
        expect(json['data']['summary']).to have_key('total_users')
        expect(json['data']['summary']).to have_key('active_players')
        expect(json['data']['summary']).to have_key('total_events')
        expect(json['data']['summary']).to have_key('upcoming_events')
        expect(json['data']['summary']).to have_key('total_announcements')
        expect(json['data']['summary']).to have_key('active_announcements')
        
        # recent_activities の確認
        expect(json['data']['recent_activities']).to have_key('recent_users')
        expect(json['data']['recent_activities']).to have_key('recent_announcements')
        expect(json['data']['recent_activities']).to have_key('upcoming_events')
        
        # quick_stats の確認
        expect(json['data']['quick_stats']).to have_key('this_month_practices')
        expect(json['data']['quick_stats']).to have_key('this_month_attendance_rate')
        expect(json['data']['quick_stats']).to have_key('pending_objectives')
      end
      
      it "統計データが正確である" do
        get "/api/v1/admin/dashboard", headers: headers
        
        json = JSON.parse(response.body)
        summary = json['data']['summary']
        
        expect(summary['total_users']).to be >= 2 # admin + player
        expect(summary['active_players']).to be >= 1 # player
        expect(summary['total_events']).to be >= 1 # attendance_event
        expect(summary['upcoming_events']).to be >= 1 # upcoming event
        expect(summary['total_announcements']).to be >= 1 # announcement
        expect(summary['active_announcements']).to be >= 1 # active announcement
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/dashboard", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
    
    context "認証されていない場合" do
      it "認証エラーが返される" do
        get "/api/v1/admin/dashboard"
        
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/admin" do
    context "管理者の場合" do
      it "ダッシュボードデータを返す（ルートパス）" do
        get "/api/v1/admin", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("管理者ダッシュボードデータを取得しました")
      end
    end
  end
end
