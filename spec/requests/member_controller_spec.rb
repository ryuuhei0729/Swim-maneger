require 'rails_helper'

RSpec.describe MemberController, type: :request do
  let(:player_user) { create(:user, :player, generation: 90, name: '田中太郎') }
  let(:coach_user) { create(:user, :coach, generation: 85, name: '佐藤コーチ') }
  let(:director_user) { create(:user, :director, generation: 80, name: '山田監督') }
  let(:player_auth) { create(:user_auth, user: player_user) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }
  let(:director_auth) { create(:user_auth, user: director_user) }

  describe '認証チェック' do
    context '未ログインの場合' do
      it 'メンバー画面にアクセスするとログイン画面にリダイレクトされる' do
        get member_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end

    context 'ログイン済みの場合' do
      before { sign_in player_auth }

      it 'メンバー画面にアクセス可能' do
        get member_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in player_auth }

    context '基本的な表示' do
      it 'メンバー画面が正常に表示される' do
        get member_path
        expect(response).to have_http_status(:ok)
      end

      it 'ページタイトルが正しく設定される' do
        get member_path
        expect(response.body).to include('Member')
      end
    end

    context 'ユーザー一覧の表示' do
      let!(:player1) { create(:user, :player, generation: 90, name: '田中太郎') }
      let!(:player2) { create(:user, :player, generation: 91, name: '佐藤次郎') }
      let!(:coach1) { create(:user, :coach, generation: 85, name: '山田コーチ') }
      let!(:director1) { create(:user, :director, generation: 80, name: '鈴木監督') }

      it '全てのユーザーが表示される' do
        get member_path
        expect(response.body).to include('田中太郎')
        expect(response.body).to include('佐藤次郎')
        expect(response.body).to include('山田コーチ')
        expect(response.body).to include('鈴木監督')
      end

      it '世代順でソートされている' do
        get member_path
        users = assigns(:users)
        expect(users.map(&:generation)).to eq(users.map(&:generation).sort)
      end

      it '同世代内では名前順でソートされている' do
        player3 = create(:user, :player, generation: 90, name: '阿部三郎')
        get member_path
        users = assigns(:users)
        generation_90_players = users.select { |u| u.generation == 90 && u.user_type == 'player' }
        expect(generation_90_players.map(&:name).sort).to eq(generation_90_players.map(&:name))
      end
    end

    context 'ユーザータイプ別のグループ化' do
      let!(:player1) { create(:user, :player, generation: 90) }
      let!(:player2) { create(:user, :player, generation: 91) }
      let!(:coach1) { create(:user, :coach, generation: 85) }
      let!(:director1) { create(:user, :director, generation: 80) }

      it 'ユーザータイプ別に正しくグループ化される' do
        get member_path
        grouped_by_type = assigns(:grouped_by_type)

        expect(grouped_by_type['player']).to include(player1, player2)
        expect(grouped_by_type['coach']).to include(coach1)
        expect(grouped_by_type['director']).to include(director1)
      end

      it 'ユーザータイプが正しい順序で並んでいる' do
        get member_path
        grouped_by_type = assigns(:grouped_by_type)
        type_order = grouped_by_type.keys
        expect(type_order).to eq([ 'player', 'coach', 'director' ])
      end
    end

    context '世代別のグループ化' do
      let!(:player1) { create(:user, :player, generation: 90) }
      let!(:player2) { create(:user, :player, generation: 91) }
      let!(:coach1) { create(:user, :coach, generation: 90) }

      it '世代別に正しくグループ化される' do
        get member_path
        grouped_by_generation = assigns(:grouped_by_generation)

        expect(grouped_by_generation[90]).to include(player1, coach1)
        expect(grouped_by_generation[91]).to include(player2)
      end
    end

    context 'サイドバーの表示' do
      let!(:player1) { create(:user, :player, generation: 90) }
      let!(:coach1) { create(:user, :coach, generation: 85) }
      let!(:director1) { create(:user, :director, generation: 80) }

      it '選手セクションが表示される' do
        get member_path
        expect(response.body).to include('選手')
        expect(response.body).to include('(1)') # 選手の人数
      end

      it 'コーチセクションが表示される' do
        get member_path
        expect(response.body).to include('コーチ')
        expect(response.body).to include('(1)') # コーチの人数
      end

      it '監督/顧問セクションが表示される' do
        get member_path
        expect(response.body).to include('監督/顧問')
        expect(response.body).to include('(1)') # 監督/顧問の人数
      end

      it '期別グループが表示される' do
        get member_path
        expect(response.body).to include('90期')
        expect(response.body).to include('(1)') # 90期の選手数
      end
    end

    context 'ユーザーカードの表示' do
      let!(:player) { create(:user, :player, generation: 90, name: '田中太郎') }

      it 'ユーザー名が表示される' do
        get member_path
        expect(response.body).to include('田中太郎')
      end

      it '世代が表示される' do
        get member_path
        expect(response.body).to include('90期')
      end

      it 'ユーザータイプが表示される' do
        get member_path
        expect(response.body).to include('選手')
      end
    end

    context 'モーダルの表示' do
      let!(:player) { create(:user, :player, generation: 90, name: '田中太郎', bio: '水泳が大好きです') }

      it 'ユーザー詳細モーダルが含まれている' do
        get member_path
        expect(response.body).to include('user-modal-')
        expect(response.body).to include('田中太郎の詳細情報')
      end

      it 'ユーザーの詳細情報が表示される' do
        get member_path
        expect(response.body).to include('田中太郎')
        expect(response.body).to include('90期')
        expect(response.body).to include('水泳が大好きです')
      end
    end
  end
end
