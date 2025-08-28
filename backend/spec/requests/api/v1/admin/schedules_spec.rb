require 'rails_helper'

RSpec.describe "Api::V1::Admin::Schedules", type: :request do
  let(:admin_user_auth) { create(:user_auth, :admin) }
  let(:admin_user) { admin_user_auth.user }
  let(:player_user_auth) { create(:user_auth, :player) }
  let(:headers) { { 'Authorization' => "Bearer #{admin_user_auth.authentication_token}" } }
  let(:player_headers) { { 'Authorization' => "Bearer #{player_user_auth.authentication_token}" } }

  describe "GET /api/v1/admin/schedules" do
    let!(:schedule1) { create(:attendance_event, title: "練習1", date: Date.today + 1.day, is_competition: false) }
    let!(:schedule2) { create(:attendance_event, title: "練習2", date: Date.today + 2.days, is_competition: false) }
    let!(:competition1) { create(:attendance_event, title: "大会1", date: Date.today + 3.days, is_competition: true) }
    let!(:competition2) { create(:attendance_event, title: "大会2", date: Date.today + 4.days, is_competition: true) }
    
    context "管理者の場合" do
      it "スケジュール一覧を返す" do
        get "/api/v1/admin/schedules", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['schedules']).to be_an(Array)
        expect(json['data']['schedules'].count).to eq(4)
      end
      
      it "event_type=practiceで練習のみを返す" do
        get "/api/v1/admin/schedules?event_type=practice", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['schedules'].count).to eq(2)
        expect(json['data']['schedules'].all? { |s| s['title'].include?('練習') }).to be true
      end
      
      it "event_type=competitionで大会のみを返す" do
        get "/api/v1/admin/schedules?event_type=competition", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['schedules'].count).to eq(2)
        expect(json['data']['schedules'].all? { |s| s['title'].include?('大会') }).to be true
      end
      
      it "無効なevent_typeでエラーを返す" do
        get "/api/v1/admin/schedules?event_type=invalid", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("無効なevent_typeです。'practice'または'competition'を指定してください")
      end
    end
    
    context "一般ユーザーの場合" do
      it "アクセス拒否される" do
        get "/api/v1/admin/schedules", headers: player_headers
        
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("管理者権限が必要です")
      end
    end
  end

  describe "GET /api/v1/admin/schedules/:id" do
    let!(:schedule) { create(:attendance_event, title: "練習1", date: Date.today + 1.day) }
    
    context "管理者の場合" do
      it "指定されたスケジュールを返す" do
        get "/api/v1/admin/schedules/#{schedule.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['schedule']['id']).to eq(schedule.id)
        expect(json['data']['schedule']['title']).to eq("練習1")
      end
    end
    
    context "存在しないIDの場合" do
      it "エラーを返す" do
        get "/api/v1/admin/schedules/99999", headers: headers
        
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("スケジュールが見つかりません")
      end
    end
  end

  describe "POST /api/v1/admin/schedules" do
    let(:valid_params) do
      {
        schedule: {
          title: "新しい練習",
          date: Date.today + 3.days,
          place: "プール",
          note: "テスト練習",
          is_competition: false,
          is_attendance: true
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "スケジュールを作成する" do
        expect {
          post "/api/v1/admin/schedules", params: valid_params, headers: headers
        }.to change(AttendanceEvent, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("スケジュールを作成しました")
        expect(json['data']['schedule']['title']).to eq("新しい練習")
      end
    end
    
    context "無効なパラメータの場合" do
      it "エラーを返す" do
        invalid_params = valid_params.deep_dup
        invalid_params[:schedule][:title] = ""
        
        post "/api/v1/admin/schedules", params: invalid_params, headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("スケジュールの作成に失敗しました")
      end
    end
  end

  describe "PATCH /api/v1/admin/schedules/:id" do
    let!(:schedule) { create(:attendance_event, title: "練習1", date: Date.today + 1.day) }
    let(:update_params) do
      {
        schedule: {
          title: "更新された練習",
          place: "新しいプール"
        }
      }
    end
    
    context "有効なパラメータの場合" do
      it "スケジュールを更新する" do
        patch "/api/v1/admin/schedules/#{schedule.id}", params: update_params, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("スケジュールを更新しました")
        expect(json['data']['schedule']['title']).to eq("更新された練習")
        
        schedule.reload
        expect(schedule.title).to eq("更新された練習")
        expect(schedule.place).to eq("新しいプール")
      end
    end
  end

  describe "DELETE /api/v1/admin/schedules/:id" do
    let!(:schedule) { create(:attendance_event, title: "練習1", date: Date.today + 1.day) }
    
    context "管理者の場合" do
      it "スケジュールを削除する" do
        expect {
          delete "/api/v1/admin/schedules/#{schedule.id}", headers: headers
        }.to change(AttendanceEvent, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq("スケジュールを削除しました")
      end
    end
  end

  describe "GET /api/v1/admin/schedules/import/template" do
    context "管理者の場合" do
      it "インポートテンプレート情報を返す" do
        get "/api/v1/admin/schedules/import/template", headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['template_url']).to be_present
        expect(json['data']['instructions']).to be_an(Array)
      end
    end
  end

  describe "POST /api/v1/admin/schedules/import/preview" do
    let(:file) { fixture_file_upload('schedule_import_test.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet') }
    
    context "有効なファイルの場合" do
      it "プレビューデータを返す" do
        # テスト用のファイルを模擬
        xlsx_double = double
        sheet_double = double
        
        # シートの行データを設定
        allow(sheet_double).to receive(:each_row_streaming).and_return([
          [
            double(value: "練習1"),
            double(value: Date.today + 1.day),
            double(value: "プール"),
            double(value: "テスト"),
            double(value: false),
            double(value: true)
          ]
        ])
        
        # xlsx_doubleがsheetメソッドを引数付きで呼び出せるように設定
        allow(xlsx_double).to receive(:sheet).with(any_args).and_return(sheet_double)
        
        # Roo::Excelx.newがxlsx_doubleを返すように設定
        allow(Roo::Excelx).to receive(:new).and_return(xlsx_double)
        
        post "/api/v1/admin/schedules/import/preview", params: { file: file }, headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['data']['preview_data']).to be_an(Array)
      end
    end
    
    context "ファイルが提供されていない場合" do
      it "エラーを返す" do
        post "/api/v1/admin/schedules/import/preview", headers: headers
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq("ファイルを選択してください")
      end
    end
  end
end
