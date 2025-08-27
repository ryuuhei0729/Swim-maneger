require 'rails_helper'

RSpec.describe "Api::V1::Practice", type: :request do
  let(:user_auth) { create(:user_auth, :player) }
  let(:user) { user_auth.user }
  let!(:other_user) { create(:user, user_type: "player") }
  let(:headers) { { 'Authorization' => "Bearer #{user_auth.authentication_token}" } }
  
  let!(:attendance_event) { create(:attendance_event, date: 1.week.ago) }
  let!(:practice_log) { create(:practice_log, attendance_event: attendance_event) }
  
  # 自分の練習タイム
  let!(:my_practice_times) do
    [
      create(:practice_time, user: user, practice_log: practice_log, set_number: 1, rep_number: 1, time: 30.5),
      create(:practice_time, user: user, practice_log: practice_log, set_number: 1, rep_number: 2, time: 31.0),
      create(:practice_time, user: user, practice_log: practice_log, set_number: 2, rep_number: 1, time: 32.0),
      create(:practice_time, user: user, practice_log: practice_log, set_number: 2, rep_number: 2, time: 32.5)
    ]
  end
  
  # 他の人の練習タイム（表示されないはず）
  let!(:other_practice_times) do
    [
      create(:practice_time, user: other_user, practice_log: practice_log, set_number: 1, rep_number: 1, time: 28.0),
      create(:practice_time, user: other_user, practice_log: practice_log, set_number: 1, rep_number: 2, time: 28.5)
    ]
  end
  
  # 別の練習記録（自分が参加していない）
  let!(:other_practice_log) { create(:practice_log, attendance_event: create(:attendance_event)) }
  let!(:other_only_practice_times) do
    [
      create(:practice_time, user: other_user, practice_log: other_practice_log, set_number: 1, rep_number: 1, time: 29.0)
    ]
  end

  describe "GET /api/v1/practice" do
    context "正常な場合" do
      it "自分が参加した練習記録一覧を取得できる" do
        get "/api/v1/practice", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["success"]).to be true
        expect(json["data"]["practice_logs"]).to be_an(Array)
        expect(json["data"]["practice_logs"].length).to eq(1)
        
        practice_data = json["data"]["practice_logs"].first
        expect(practice_data["id"]).to eq(practice_log.id)
        expect(practice_data["style"]).to eq(practice_log.style)
        expect(practice_data["style_name"]).to eq(PracticeLog::STYLE_OPTIONS[practice_log.style])
        expect(practice_data["distance"]).to eq(practice_log.distance)
        expect(practice_data["my_times_count"]).to eq(4)
        expect(practice_data["my_best_time"]).to eq(30.5)
        expect(practice_data["my_average_time"]).to eq(31.5)
      end
      
      it "ページネーションが正しく動作する" do
        get "/api/v1/practice", params: { page: 1, per_page: 5 }, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        pagination = json["data"]["pagination"]
        expect(pagination["current_page"]).to eq(1)
        expect(pagination["per_page"]).to eq(5)
        expect(pagination["total_count"]).to eq(1)
        expect(pagination["total_pages"]).to eq(1)
        expect(pagination["has_next"]).to be false
        expect(pagination["has_prev"]).to be false
      end
      
      it "統計情報が含まれる" do
        get "/api/v1/practice", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        statistics = json["data"]["statistics"]
        expect(statistics["total_practice_sessions"]).to eq(1)
        expect(statistics["total_times_recorded"]).to eq(4)
        expect(statistics["style_statistics"]).to be_a(Hash)
      end
    end

    context "認証されていない場合" do
      it "401エラーを返す" do
        get "/api/v1/practice"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/practice/:id" do
    context "正常な場合" do
      it "練習記録の詳細を取得できる" do
        get "/api/v1/practice/#{practice_log.id}", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["success"]).to be true
        practice_data = json["data"]["practice_log"]
        expect(practice_data["id"]).to eq(practice_log.id)
        expect(practice_data["style"]).to eq(practice_log.style)
        expect(practice_data["distance"]).to eq(practice_log.distance)
        
        summary = json["data"]["summary"]
        expect(summary["participation_stats"]["completed_reps"]).to eq(4)
        expect(summary["time_stats"]["best_time"]).to eq(30.5)
      end
    end

    context "自分が参加していない練習記録の場合" do
      it "404エラーを返す" do
        get "/api/v1/practice/#{other_practice_log.id}", headers: headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["message"]).to include("タイムが記録されていません")
      end
    end

    context "存在しない練習記録の場合" do
      it "404エラーを返す" do
        get "/api/v1/practice/99999", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/practice/:id/practice_times" do
    context "正常な場合" do
      it "詳細な練習タイムデータを取得できる" do
        get "/api/v1/practice/#{practice_log.id}/practice_times", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["success"]).to be true
        
        practice_data = json["data"]["practice_log"]
        expect(practice_data["id"]).to eq(practice_log.id)
        
        times_data = json["data"]["practice_times"]
        expect(times_data["sets"]).to be_an(Array)
        expect(times_data["sets"].length).to eq(2) # 2セット
        
        # セット1のデータ確認
        set1 = times_data["sets"].find { |s| s["set_number"] == 1 }
        expect(set1["reps"].length).to eq(2)
        expect(set1["set_stats"]["best_time"]).to eq(30.5)
        expect(set1["set_stats"]["average_time"]).to eq(30.75)
        
        # セット2のデータ確認
        set2 = times_data["sets"].find { |s| s["set_number"] == 2 }
        expect(set2["reps"].length).to eq(2)
        expect(set2["set_stats"]["best_time"]).to eq(32.0)
        expect(set2["set_stats"]["average_time"]).to eq(32.25)
        
        # 全体統計
        overall_stats = times_data["overall_stats"]
        expect(overall_stats["total_times"]).to eq(4)
        expect(overall_stats["overall_best"]).to eq(30.5)
        expect(overall_stats["overall_average"]).to eq(31.5)
        
        # 分析データ
        analytics = json["data"]["analytics"]
        expect(analytics["consistency_score"]).to be_a(Numeric)
        expect(analytics["fatigue_index"]).to be_a(Numeric)
      end
      
      it "セット別の統計が正しく計算される" do
        get "/api/v1/practice/#{practice_log.id}/practice_times", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        times_data = json["data"]["practice_times"]
        set1 = times_data["sets"].find { |s| s["set_number"] == 1 }
        
        expect(set1["set_stats"]["total_reps"]).to eq(2)
        expect(set1["set_stats"]["best_time"]).to eq(30.5)
        expect(set1["set_stats"]["worst_time"]).to eq(31.0)
        expect(set1["set_stats"]["average_time"]).to eq(30.75)
      end
    end

    context "自分が参加していない練習記録の場合" do
      it "404エラーを返す" do
        get "/api/v1/practice/#{other_practice_log.id}/practice_times", headers: headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end
    end
  end

  describe "データフォーマット確認" do
    it "時間が正しくフォーマットされる" do
      get "/api/v1/practice", headers: headers

      json = JSON.parse(response.body)
      practice_data = json["data"]["practice_logs"].first
      
      expect(practice_data["formatted_best_time"]).to eq("30.50")
      expect(practice_data["formatted_average_time"]).to eq("31.50")
    end
    
    it "距離が正しくフォーマットされる" do
      get "/api/v1/practice/#{practice_log.id}", headers: headers

      json = JSON.parse(response.body)
      practice_data = json["data"]["practice_log"]
      
      expect(practice_data["formatted_distance"]).to eq("#{practice_log.distance}m")
      expect(practice_data["formatted_total_distance"]).to eq("#{practice_log.distance * practice_log.rep_count * practice_log.set_count}m")
    end
  end

  describe "権限確認" do
    it "他のユーザーのタイムは表示されない" do
      get "/api/v1/practice", headers: headers

      json = JSON.parse(response.body)
      practice_data = json["data"]["practice_logs"].first
      
      # 自分のタイムのみカウントされる（他の人の2つのタイムは含まれない）
      expect(practice_data["my_times_count"]).to eq(4)
    end
    
    it "自分が参加していない練習記録は一覧に表示されない" do
      get "/api/v1/practice", headers: headers

      json = JSON.parse(response.body)
      practice_logs = json["data"]["practice_logs"]
      
      # other_practice_logは表示されない
      practice_log_ids = practice_logs.map { |log| log["id"] }
      expect(practice_log_ids).not_to include(other_practice_log.id)
      expect(practice_log_ids).to include(practice_log.id)
    end
  end

  describe "エラーハンドリング" do
    it "無効なページ番号でもエラーにならない" do
      get "/api/v1/practice", params: { page: -1 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["pagination"]["current_page"]).to eq(1)
    end
    
    it "per_pageの上限が適用される" do
      get "/api/v1/practice", params: { per_page: 100 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["pagination"]["per_page"]).to eq(50) # 最大50に制限
    end
  end
end
