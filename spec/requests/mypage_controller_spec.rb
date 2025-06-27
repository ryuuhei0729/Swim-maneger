require 'rails_helper'

RSpec.describe MypageController, type: :request do
  let(:user) { create(:user, :player, name: '田中太郎', generation: 90, bio: '水泳が大好きです') }
  let(:user_auth) { create(:user_auth, user: user) }

  describe '認証チェック' do
    context '未ログインの場合' do
      it 'マイページにアクセスするとログイン画面にリダイレクトされる' do
        get mypage_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before { sign_in user_auth }

      it 'マイページにアクセス可能' do
        get mypage_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in user_auth }

    context '基本的な表示' do
      it 'マイページが正常に表示される' do
        get mypage_path
        expect(response).to have_http_status(:ok)
      end

      it 'ページタイトルが正しく設定される' do
        get mypage_path
        expect(response.body).to include('Mypage')
      end
    end

    context 'ユーザー情報の表示' do
      it 'ユーザー名が表示される' do
        get mypage_path
        expect(response.body).to include('田中太郎')
      end

      it '世代が表示される' do
        get mypage_path
        expect(response.body).to include('90th')
      end

      it '誕生日が表示される' do
        get mypage_path
        expect(response.body).to include(user.birthday.strftime('%Y年%m月%d日'))
      end

      it '自己紹介が表示される' do
        get mypage_path
        expect(response.body).to include('水泳が大好きです')
      end

      it '自己紹介が設定されていない場合はデフォルトメッセージが表示される' do
        user.update!(bio: nil)
        get mypage_path
        expect(response.body).to include('自己紹介が設定されていません')
      end
    end

    context '記録の表示' do
      let!(:style) { create(:style, :freestyle, :distance_50, name: '50M_FR', name_jp: '50m自由形') }
      let!(:record1) { create(:record, user: user, style: style, time: 25.5, created_at: 1.day.ago) }
      let!(:record2) { create(:record, user: user, style: style, time: 26.0, created_at: 2.days.ago) }

      it '記録が作成日順（降順）で表示される' do
        get mypage_path
        records = assigns(:records)
        expect(records.first).to eq(record1)
        expect(records.second).to eq(record2)
      end

      it '記録履歴テーブルが表示される' do
        get mypage_path
        expect(response.body).to include('My Records')
        expect(response.body).to include('50m自由形')
        expect(response.body).to include('25.50')
      end
    end

    context 'ベストタイムの表示' do
      let!(:style1) { create(:style, :freestyle, :distance_50, name: '50M_FR', name_jp: '50m自由形') }
      let!(:style2) { create(:style, :breaststroke, :distance_100, name: '100M_BR', name_jp: '100m平泳ぎ') }
      let!(:record1) { create(:record, user: user, style: style1, time: 25.5) }
      let!(:record2) { create(:record, user: user, style: style1, time: 26.0) }
      let!(:record3) { create(:record, user: user, style: style2, time: 80.0) }

      it '各種目のベストタイムが取得される' do
        get mypage_path
        best_times = assigns(:best_times)
        
        expect(best_times['50M_FR']).to eq(25.5) # より速いタイムが選択される
        expect(best_times['100M_BR']).to eq(80.0)
      end

      it 'ベストタイム一覧が表示される' do
        get mypage_path
        expect(response.body).to include('My Best Time')
        expect(response.body).to include('自由形')
        expect(response.body).to include('平泳ぎ')
      end

      it '記録がない種目は「-」で表示される' do
        other_style = create(:style, :backstroke, :distance_200, name: '200M_BA', name_jp: '200m背泳ぎ')
        get mypage_path
        best_times = assigns(:best_times)
        expect(best_times['200M_BA']).to be_nil
      end
    end

    context '編集モーダルの表示' do
      it '編集ボタンが表示される' do
        get mypage_path
        expect(response.body).to include('編集')
      end

      it '編集モーダルが含まれている' do
        get mypage_path
        expect(response.body).to include('edit-modal')
        expect(response.body).to include('自己紹介文の編集')
      end
    end
  end

  describe 'PATCH #update' do
    before { sign_in user_auth }

    context '正常な更新' do
      it '自己紹介を更新できる' do
        patch mypage_path, params: { user: { bio: '新しい自己紹介です' } }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('プロフィールを更新しました')
        expect(user.reload.bio).to eq('新しい自己紹介です')
      end

      it '自己紹介を空にできる' do
        patch mypage_path, params: { user: { bio: '' } }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('プロフィールを更新しました')
        expect(user.reload.bio).to be_blank
      end
    end

    context '画像アップロード' do
      let(:valid_image) { fixture_file_upload('spec/fixtures/test_image.jpg', 'image/jpeg') }
      let(:invalid_file) { fixture_file_upload('spec/fixtures/test_image.jpg', 'text/plain') }

      it '有効な画像形式（JPG）をアップロードできる' do
        patch mypage_path, params: { user: { avatar: valid_image } }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('プロフィールを更新しました')
        expect(user.reload.avatar).to be_attached
      end

      it '無効なファイル形式をアップロードするとエラーメッセージが表示される' do
        patch mypage_path, params: { user: { avatar: invalid_file } }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:alert]).to eq('JPGまたはPNG形式の画像のみアップロード可能です')
      end

      it '画像と自己紹介を同時に更新できる' do
        patch mypage_path, params: { 
          user: { 
            bio: '画像付きの自己紹介です',
            avatar: valid_image 
          } 
        }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq('プロフィールを更新しました')
        expect(user.reload.bio).to eq('画像付きの自己紹介です')
        expect(user.avatar).to be_attached
      end
    end

    context '更新失敗' do
      it '無効なパラメータで更新に失敗した場合エラーメッセージが表示される' do
        # 無効なパラメータを送信（例：存在しない属性）
        allow_any_instance_of(User).to receive(:update).and_return(false)
        
        patch mypage_path, params: { user: { bio: '新しい自己紹介です' } }
        
        expect(response).to redirect_to(mypage_path)
        expect(flash[:alert]).to eq('プロフィールの更新に失敗しました')
      end
    end

    context 'パラメータの検証' do
      it '許可されていないパラメータは無視される' do
        original_name = user.name
        patch mypage_path, params: { user: { name: '新しい名前', bio: '新しい自己紹介' } }
        
        expect(user.reload.name).to eq(original_name) # 名前は変更されない
        expect(user.bio).to eq('新しい自己紹介') # 自己紹介は変更される
      end
    end
  end
end 