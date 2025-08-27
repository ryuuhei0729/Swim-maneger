require 'rails_helper'

RSpec.describe "Api::V1::Admin::Users", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/users" do
    let!(:user1) { create(:user, :player, name: "選手1", generation: 1) }
    let!(:user2) { create(:user, :coach, name: "コーチ1", generation: 2) }
    
    context "管理者の場合" do
      it "ユーザー一覧を返す" do
        get "/api/v1/admin/users", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['users']).to be_an(Array)
        expect(json['data']['total_count']).to be >= 2
        expect(json['data']['user_types']).to be_an(Array)
        expect(json['data']['genders']).to be_an(Array)
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/users", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/users/:id" do
    let!(:user) { create(:user, :player, name: "選手1") }
    
    context "管理者の場合" do
      it "指定されたユーザーを返す" do
        get "/api/v1/admin/users/#{user.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['user']['id']).to eq(user.id)
        expect(json['data']['user']['name']).to eq("選手1")
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/users/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("ユーザーが見つかりません")
      end
    end
  end

  describe "POST /api/v1/admin/users" do
    let(:valid_params) do
      {
        user: {
          name: "新しいユーザー",
          user_type: "player",
          generation: 1,
          gender: "male",
          birthday: "2000-01-01"
        },
        user_auth: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "ユーザーを作成する" do
        expect {
          post "/api/v1/admin/users", params: valid_params, headers: headers
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("ユーザーを作成しました")
        expect(json['data']['user']['name']).to eq("新しいユーザー")
      end
    end
    
    context "無効なパラメータの場合" do
      it "エラーを返す" do
        invalid_params = valid_params.deep_dup
        invalid_params[:user][:name] = ""
        
        post "/api/v1/admin/users", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("ユーザーの作成に失敗しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/users/:id" do
    let!(:user) { create(:user, :player, name: "選手1") }
    let!(:user_auth) { create(:user_auth, user: user, email: "old@example.com") }
    
    let(:update_params) do
      {
        user: {
          name: "更新された選手",
          generation: 2
        },
        user_auth: {
          email: "new@example.com"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "ユーザーを更新する" do
        patch "/api/v1/admin/users/#{user.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("ユーザー情報を更新しました")
        expect(json['data']['user']['name']).to eq("更新された選手")
        
        user.reload
        user_auth.reload
        expect(user.name).to eq("更新された選手")
        expect(user.generation).to eq(2)
        expect(user_auth.email).to eq("new@example.com")
      end
    end
  end

  describe "DELETE /api/v1/admin/users/:id" do
    let!(:user) { create(:user, :player, name: "削除テスト選手") }
    
    context "管理者の場合" do
      it "ユーザー削除機能が無効化されていることを確認する" do
        expect {
          delete "/api/v1/admin/users/#{user.id}", headers: headers
        }.to change(User, :count).by(0)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("ユーザー削除機能は現在無効化されています")
      end
    end
  end

  describe "GET /api/v1/admin/users/import/template" do
    context "管理者の場合" do
      it "インポートテンプレート情報を返す" do
        get "/api/v1/admin/users/import/template", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['template_url']).to be_present
        expect(json['data']['instructions']).to be_an(Array)
        expect(json['data']['sample_data']).to be_an(Array)
      end
    end
  end

  describe "POST /api/v1/admin/users/import/preview" do
    let(:file) { fixture_file_upload('user_import_test.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }
    
    context "有効なファイルの場合" do
      it "プレビューデータを返す" do
        # テスト用のファイルを模擬
        xlsx_double = double
        sheet_double = double
        
        # シートの行データを設定（ヘッダー行をスキップするため、offset: 1で呼ばれる）
        allow(sheet_double).to receive(:each_row_streaming).with(offset: 1).and_return([
          [
            double(value: "田中太郎"),
            double(value: "player"),
            double(value: 1),
            double(value: "male"),
            double(value: Date.parse("2000-01-01")),
            double(value: "tanaka@example.com"),
            double(value: "password123")
          ]
        ])
        
        # xlsx_doubleがsheetメソッドを引数付きで呼び出せるように設定
        allow(xlsx_double).to receive(:sheet).with(any_args).and_return(sheet_double)
        
        # Roo::Excelx.newがxlsx_doubleを返すように設定
        allow(Roo::Excelx).to receive(:new).and_return(xlsx_double)
        
        post "/api/v1/admin/users/import/preview", params: { file: file }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['preview_data']).to be_an(Array)
      end
    end
    
    context "ファイルが提供されていない場合" do
      it "エラーを返す" do
        post "/api/v1/admin/users/import/preview", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("ファイルを選択してください")
      end
    end
  end

  describe "POST /api/v1/admin/users/import/execute" do
    let(:valid_preview_data) do
      {
        preview_data: [
          {
            row_number: 2,
            name: "田中太郎",
            user_type: "player",
            generation: 1,
            gender: "male",
            birthday: "2000-01-01",
            email: "tanaka@example.com",
            password: "password123",
            valid: true
          }
        ]
      }
    end
    
    context "有効なプレビューデータの場合" do
      it "ユーザーを一括作成する" do
        expect {
          post "/api/v1/admin/users/import/execute", params: valid_preview_data, headers: headers
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("1人のユーザーを一括インポートしました")
      end
    end
    
    context "インポートデータが提供されていない場合" do
      it "エラーを返す" do
        post "/api/v1/admin/users/import/execute", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("インポートトークンが見つかりません")
      end
    end
  end
end
