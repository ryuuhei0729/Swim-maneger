require 'rails_helper'

RSpec.describe "Api::V1::Admin::Announcements", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/announcements" do
    let!(:announcement1) { create(:announcement, title: "お知らせ1", is_active: true) }
    let!(:announcement2) { create(:announcement, title: "お知らせ2", is_active: false) }
    
    context "管理者の場合" do
      it "お知らせ一覧を返す" do
        get "/api/v1/admin/announcements", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['announcements']).to be_an(Array)
        expect(json['data']['total_count']).to eq(2)
        expect(json['data']['active_count']).to eq(1)
        expect(json['data']['inactive_count']).to eq(1)
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/announcements", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/announcements/:id" do
    let!(:announcement) { create(:announcement, title: "テストお知らせ") }
    
    context "管理者の場合" do
      it "指定されたお知らせを返す" do
        get "/api/v1/admin/announcements/#{announcement.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['announcement']['id']).to eq(announcement.id)
        expect(json['data']['announcement']['title']).to eq("テストお知らせ")
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/announcements/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("お知らせが見つかりません")
      end
    end
  end

  describe "POST /api/v1/admin/announcements" do
    let(:valid_params) do
      {
        announcement: {
          title: "新しいお知らせ",
          content: "お知らせの内容です",
          is_active: true,
          published_at: Time.current
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "お知らせを作成する" do
        expect {
          post "/api/v1/admin/announcements", params: valid_params, headers: headers
        }.to change(Announcement, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("お知らせを作成しました")
        expect(json['data']['announcement']['title']).to eq("新しいお知らせ")
      end
    end
    
    context "無効なパラメータの場合" do
      it "エラーを返す" do
        invalid_params = valid_params.deep_dup
        invalid_params[:announcement][:title] = ""
        
        post "/api/v1/admin/announcements", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("お知らせの作成に失敗しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/announcements/:id" do
    let!(:announcement) { create(:announcement, title: "元のタイトル", content: "元の内容") }
    
    let(:update_params) do
      {
        announcement: {
          title: "更新されたタイトル",
          content: "更新された内容"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "お知らせを更新する" do
        patch "/api/v1/admin/announcements/#{announcement.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("お知らせを更新しました")
        
        announcement.reload
        expect(announcement.title).to eq("更新されたタイトル")
        expect(announcement.content).to eq("更新された内容")
      end
    end
  end

  describe "DELETE /api/v1/admin/announcements/:id" do
    let!(:announcement) { create(:announcement, title: "削除するお知らせ") }
    
    context "管理者の場合" do
      it "お知らせを削除する" do
        expect {
          delete "/api/v1/admin/announcements/#{announcement.id}", headers: headers
        }.to change(Announcement, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("お知らせを削除しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/announcements/:id/toggle_active" do
    let!(:announcement) { create(:announcement, title: "テストお知らせ", is_active: false) }
    
    context "管理者の場合" do
      it "お知らせの公開状態を切り替える" do
        patch "/api/v1/admin/announcements/#{announcement.id}/toggle_active", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("お知らせを公開にしました")
        
        announcement.reload
        expect(announcement.is_active).to be true
      end
    end
  end

  describe "POST /api/v1/admin/announcements/bulk_action" do
    let!(:announcement1) { create(:announcement, title: "お知らせ1", is_active: false) }
    let!(:announcement2) { create(:announcement, title: "お知らせ2", is_active: false) }
    
    context "一括公開の場合" do
      it "指定されたお知らせを一括公開する" do
        post "/api/v1/admin/announcements/bulk_action", 
             params: { 
               action_type: 'activate',
               announcement_ids: [announcement1.id, announcement2.id]
             }, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("2件のお知らせを公開しました")
        
        announcement1.reload
        announcement2.reload
        expect(announcement1.is_active).to be true
        expect(announcement2.is_active).to be true
      end
    end
    
    context "一括削除の場合" do
      it "指定されたお知らせを一括削除する" do
        expect {
          post "/api/v1/admin/announcements/bulk_action", 
               params: { 
                 action_type: 'delete',
                 announcement_ids: [announcement1.id, announcement2.id]
               }, 
               headers: headers
        }.to change(Announcement, :count).by(-2)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("2件のお知らせを削除しました")
      end
    end
  end

  describe "GET /api/v1/admin/announcements/statistics" do
    let!(:announcement1) { create(:announcement, is_active: true, created_at: 1.week.ago) }
    let!(:announcement2) { create(:announcement, is_active: false, created_at: 2.weeks.ago) }
    
    context "管理者の場合" do
      it "統計データを返す" do
        get "/api/v1/admin/announcements/statistics", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['total_count']).to eq(2)
        expect(json['data']['active_count']).to eq(1)
        expect(json['data']['inactive_count']).to eq(1)
      end
    end
  end
end
