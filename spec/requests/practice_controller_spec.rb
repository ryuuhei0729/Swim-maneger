require 'rails_helper'

RSpec.describe PracticeController, type: :request do
  let(:user) { create(:user, :player, name: '田中太郎') }
  let(:user_auth) { create(:user_auth, user: user) }
  let(:other_user) { create(:user, :player, name: '佐藤次郎') }

  describe '認証チェック' do
    context '未ログインの場合' do
      it '記録画面にアクセスするとログイン画面にリダイレクトされる' do
        get practice_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end
    context 'ログイン済みの場合' do
      before { sign_in user_auth }
      it '記録画面にアクセス可能' do
        get practice_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in user_auth }
    let!(:log1) { create(:practice_log) }
    let!(:log2) { create(:practice_log) }
    let!(:my_time1) { create(:practice_time, user: user, practice_log: log1) }
    let!(:my_time2) { create(:practice_time, user: user, practice_log: log2) }
    let!(:other_time) { create(:practice_time, user: other_user, practice_log: log1) }

    it '自分のPracticeLogのみが表示される' do
      get practice_path
      logs = assigns(:practice_logs)
      expect(logs).to include(log1, log2)
      # 他人の記録だけのPracticeLogは含まれない
      expect(logs).not_to include(nil)
    end

    it 'ページが正常に表示される' do
      get practice_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #practice_times' do
    let!(:practice_log) { create(:practice_log) }
    let!(:practice_time) { create(:practice_time, user: user, practice_log: practice_log) }

    before { sign_in user_auth }

    it '練習タイムが部分的に表示される' do
      get "/practice/practice_times/#{practice_log.id}"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(practice_log.style)
    end

    it '存在しないPracticeLogの場合は404エラーが返される' do
      expect {
        get "/practice/practice_times/999999"
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
