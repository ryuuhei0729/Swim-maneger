require 'rails_helper'

RSpec.describe ErrorsController, type: :request do
  let(:user) { create(:user, :player) }
  let(:user_auth) { create(:user_auth, user: user) }

  describe 'エラーハンドリングの動作確認' do
    context '存在しないページにアクセスした場合' do
      it '404エラーページが表示される' do
        get '/nonexistent_page'
        expect(response).to have_http_status(:not_found)
      end

      it 'ログイン済みでも404エラーページが表示される' do
        sign_in user_auth
        get '/nonexistent_page'
        expect(response).to have_http_status(:not_found)
      end
    end

    context '存在しないリソースにアクセスした場合' do
      before { sign_in user_auth }

      it 'RecordNotFoundで404エラーページが表示される' do
        expect {
          # 存在しないIDでアクセス
          get "/admin/announcements/999999/edit"
        }.not_to raise_error

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'エラーページの表示内容' do
    context '404エラーページ' do
      it 'エラー情報が適切に表示される' do
        get '/nonexistent_page'
        expect(response).to have_http_status(:not_found)
        # エラーページファイルが存在することを確認
        expect(File.exist?("#{Rails.root}/app/views/errors/not_found.html.erb")).to be true
      end
    end
  end

  describe 'コントローラーの基本設定' do
    it 'ApplicationControllerを継承している' do
      expect(ErrorsController.superclass).to eq(ApplicationController)
    end

    it '認証をスキップして未ログインでもアクセス可能' do
      # 認証スキップの動作確認（実際に動作することで間接的に確認）
      get '/nonexistent_page'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'エラーページファイルの存在確認' do
    it '404エラーページテンプレートが存在する' do
      expect(File.exist?("#{Rails.root}/app/views/errors/not_found.html.erb")).to be true
    end

    it '500エラーページテンプレートが存在する' do
      expect(File.exist?("#{Rails.root}/app/views/errors/internal_server_error.html.erb")).to be true
    end

    it '422エラーページテンプレートが存在する' do
      expect(File.exist?("#{Rails.root}/app/views/errors/unprocessable_entity.html.erb")).to be true
    end
  end
end 