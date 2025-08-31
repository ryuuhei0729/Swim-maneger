require 'rails_helper'

RSpec.describe "Api::V1::Admin::Objectives", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:player_user) { player_user_auth.user }
  let(:headers) { auth_headers(admin_user_auth) }
  let(:player_headers) { auth_headers(player_user_auth) }

  describe "GET /api/v1/admin/objectives" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    
    context "管理者の場合" do
      it "目標一覧を返す" do
        get "/api/v1/admin/objectives", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['objectives']).to be_an(Array)
        expect(json['data']['total_count']).to eq(1)
        expect(json['data']['filters']).to have_key('users')
        expect(json['data']['filters']).to have_key('events')
        expect(json['data']['filters']).to have_key('styles')
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/objectives", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/objectives/:id" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    let!(:milestone) { create(:milestone, objective: objective) }
    
    context "管理者の場合" do
      it "指定された目標を返す" do
        get "/api/v1/admin/objectives/#{objective.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['objective']['id']).to eq(objective.id)
        expect(json['data']['milestones']).to be_an(Array)
        expect(json['data']['milestones'].count).to eq(1)
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/objectives/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("目標が見つかりません")
      end
    end
  end

  describe "POST /api/v1/admin/objectives" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    
    let(:valid_params) do
      {
        objective: {
          user_id: player_user.id,
          attendance_event_id: attendance_event.id,
          style_id: style.id,
          target_time: 120.5,
          quantity_note: "量的目標のメモ",
          quality_title: "質的目標のタイトル",
          quality_note: "質的目標のメモ"
        },
        milestones: [
          {
            milestone_type: "quality",
            limit_date: Date.current + 1.month,
            note: "質的マイルストーン"
          },
          {
            milestone_type: "quantity",
            limit_date: Date.current + 2.weeks,
            note: "量的マイルストーン"
          }
        ]
      }
    end
    
    context "有効なパラメータの場合" do
      it "目標とマイルストーンを作成する" do
        expect {
          post "/api/v1/admin/objectives", params: valid_params, headers: headers
        }.to change(Objective, :count).by(1).and change(Milestone, :count).by(2)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("目標を作成しました")
      end
    end
    
    context "無効なパラメータの場合" do
      it "エラーを返す" do
        invalid_params = valid_params.deep_dup
        invalid_params[:objective][:target_time] = nil
        
        post "/api/v1/admin/objectives", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("目標の作成に失敗しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/objectives/:id" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    
    let(:update_params) do
      {
        objective: {
          target_time: 115.0,
          quality_title: "更新された質的目標"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "目標を更新する" do
        patch "/api/v1/admin/objectives/#{objective.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("目標を更新しました")
        
        objective.reload
        expect(objective.target_time).to eq(115.0)
        expect(objective.quality_title).to eq("更新された質的目標")
      end
    end
  end

  describe "DELETE /api/v1/admin/objectives/:id" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    
    context "管理者の場合" do
      it "目標を削除する" do
        expect {
          delete "/api/v1/admin/objectives/#{objective.id}", headers: headers
        }.to change(Objective, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("目標を削除しました")
      end
    end
  end

  describe "GET /api/v1/admin/objectives/dashboard" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    let!(:milestone) { create(:milestone, objective: objective, limit_date: Date.current + 3.days) }
    
    context "管理者の場合" do
      it "ダッシュボード統計データを返す" do
        get "/api/v1/admin/objectives/dashboard", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['statistics']).to have_key('total_objectives')
        expect(json['data']['upcoming_deadlines']).to be_an(Array)
        expect(json['data']['recent_objectives']).to be_an(Array)
      end
    end
  end

  describe "POST /api/v1/admin/objectives/:id/milestones" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    
    let(:milestone_params) do
      {
        milestone: {
          milestone_type: "quality",
          limit_date: Date.current + 1.month,
          note: "新しいマイルストーン"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "マイルストーンを作成する" do
        expect {
          post "/api/v1/admin/objectives/#{objective.id}/milestones", params: milestone_params, headers: headers
        }.to change(Milestone, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("マイルストーンを作成しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/objectives/milestones/:milestone_id" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    let!(:milestone) { create(:milestone, objective: objective, note: "元のメモ") }
    
    let(:update_params) do
      {
        milestone: {
          note: "更新されたメモ"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "マイルストーンを更新する" do
        patch "/api/v1/admin/objectives/milestones/#{milestone.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("マイルストーンを更新しました")
        
        milestone.reload
        expect(milestone.note).to eq("更新されたメモ")
      end
    end
  end

  describe "DELETE /api/v1/admin/objectives/milestones/:milestone_id" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    let!(:milestone) { create(:milestone, objective: objective) }
    
    context "管理者の場合" do
      it "マイルストーンを削除する" do
        expect {
          delete "/api/v1/admin/objectives/milestones/#{milestone.id}", headers: headers
        }.to change(Milestone, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("マイルストーンを削除しました")
      end
    end
  end

  describe "POST /api/v1/admin/objectives/milestones/:milestone_id/review" do
    let!(:attendance_event) { create(:attendance_event, is_competition: true) }
    let!(:style) { create(:style) }
    let!(:objective) { create(:objective, user: player_user, attendance_event: attendance_event, style: style) }
    let!(:milestone) { create(:milestone, objective: objective) }
    
    let(:review_params) do
      {
        milestone_review: {
          achievement_rate: 75,
          negative_note: "改善点のメモ",
          positive_note: "良かった点のメモ"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "マイルストーンレビューを作成する" do
        expect {
          post "/api/v1/admin/objectives/milestones/#{milestone.id}/review", params: review_params, headers: headers
        }.to change(MilestoneReview, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("マイルストーンレビューを作成しました")
        expect(json['data']['review']['achievement_rate']).to eq(75)
      end
    end
  end
end
