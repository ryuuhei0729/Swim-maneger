require 'rails_helper'

RSpec.describe "Api::V1::Admin::Competitions", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/competitions" do
    let!(:upcoming_competition) { create(:competition, title: "今後の大会", date: Date.today + 1.month) }
    let!(:past_competition) { create(:competition, title: "過去の大会", date: Date.today - 1.month) }
    
    context "管理者の場合" do
      it "大会一覧を返す" do
        get "/api/v1/admin/competitions", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['upcoming_competitions']).to be_an(Array)
        expect(json['data']['all_competitions']).to be_an(Array)
        expect(json['data']['collecting_entries']).to be_an(Array)
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/competitions", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/competitions/:id" do
    let!(:competition) { create(:competition, title: "テスト大会", date: Date.today + 1.month) }
    
    context "管理者の場合" do
      it "指定された大会を返す" do
        get "/api/v1/admin/competitions/#{competition.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['competition']['id']).to eq(competition.id)
        expect(json['data']['competition']['title']).to eq("テスト大会")
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/competitions/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("大会が見つかりません")
      end
    end
  end

  describe "PATCH /api/v1/admin/competitions/:id/entry_status" do
    let!(:competition) { create(:competition, title: "テスト大会", entry_status: :before) }
    
    context "有効なentry_statusの場合" do
      it "エントリー状況を更新する" do
        patch "/api/v1/admin/competitions/#{competition.id}/entry_status", 
              params: { entry_status: "open" }, 
              headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("エントリー受付状況を更新しました")
        
        competition.reload
        expect(competition.entry_status).to eq("open")
      end
    end
    
    context "無効なentry_statusの場合" do
      it "エラーを返す" do
        patch "/api/v1/admin/competitions/#{competition.id}/entry_status", 
              params: { entry_status: "invalid_status" }, 
              headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("無効なエントリー状況です")
      end
    end
  end

  describe "GET /api/v1/admin/competitions/:id/result" do
    let!(:competition) { create(:competition, title: "テスト大会") }
    let!(:user) { create(:user, :player) }
    let!(:style) { create(:style) }
    let!(:entry) { create(:entry, user: user, attendance_event: competition, style: style) }
    
    context "管理者の場合" do
      it "大会結果情報を返す" do
        get "/api/v1/admin/competitions/#{competition.id}/result", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['competition']['id']).to eq(competition.id)
        expect(json['data']['entries']).to be_an(Array)
        expect(json['data']['entries'].first['user']['name']).to eq(user.name)
      end
    end
  end

  describe "POST /api/v1/admin/competitions/:id/save_results" do
    let!(:competition) { create(:competition, title: "テスト大会") }
    let!(:user) { create(:user, :player) }
    let!(:style) { create(:style) }
    let!(:entry) { create(:entry, user: user, attendance_event: competition, style: style) }
    
    let(:valid_results) do
      {
        results: [
          {
            entry_id: entry.id,
            time: "1:23.45",
            note: "Good swim",
            split_times: [
              { distance: 50, time: "30.12" },
              { distance: 100, time: "1:03.45" }
            ]
          }
        ]
      }
    end
    
    context "有効な結果データの場合" do
      it "結果を保存する" do
        expect {
          post "/api/v1/admin/competitions/#{competition.id}/save_results", 
               params: valid_results, 
               headers: headers
        }.to change(Record, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("1件の結果を保存しました")
      end
    end
    
    context "結果データが提供されていない場合" do
      it "エラーを返す" do
        post "/api/v1/admin/competitions/#{competition.id}/save_results", 
             headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("結果データが提供されていません")
      end
    end
  end

  describe "GET /api/v1/admin/competitions/:competition_id/entries" do
    let!(:competition) { create(:competition, title: "テスト大会") }
    let!(:user1) { create(:user, :player, name: "選手1") }
    let!(:user2) { create(:user, :player, name: "選手2") }
    let!(:style) { create(:style, name_jp: "自由形") }
    let!(:entry1) { create(:entry, user: user1, attendance_event: competition, style: style) }
    let!(:entry2) { create(:entry, user: user2, attendance_event: competition, style: style) }
    
    context "管理者の場合" do
      it "大会のエントリー情報を返す" do
        get "/api/v1/admin/competitions/#{competition.id}/entries", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['competition']['id']).to eq(competition.id)
        expect(json['data']['entries'].count).to eq(2)
        expect(json['data']['entries_by_style']).to have_key("自由形")
      end
    end
  end

  describe "POST /api/v1/admin/competitions/entry/start" do
    let!(:competition) { create(:competition, title: "テスト大会", entry_status: :before) }
    
    context "管理者の場合" do
      it "エントリー受付を開始する" do
        post "/api/v1/admin/competitions/entry/start", 
             params: { event_id: competition.id }, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("#{competition.title}のエントリー受付を開始しました")
        
        competition.reload
        expect(competition.entry_status).to eq("open")
      end
    end
    
    context "存在しない大会IDの場合" do
      it "エラーを返す" do
        post "/api/v1/admin/competitions/entry/start", 
             params: { event_id: 99999 }, 
             headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end
end
