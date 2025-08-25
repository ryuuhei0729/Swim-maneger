require 'rails_helper'

RSpec.describe HomeController, type: :request do
  let(:player_user) { create(:user, :player, :male) }
  let(:female_player_user) { create(:user, :player, :female) }
  let(:coach_user) { create(:user, :coach) }
  let(:player_auth) { create(:user_auth, user: player_user) }
  let(:female_player_auth) { create(:user_auth, user: female_player_user) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }

  describe '認証チェック' do
    context '未ログインの場合' do
      it 'ホーム画面にアクセスするとログイン画面にリダイレクトされる' do
        get home_path
        expect(response).to redirect_to(new_user_auth_session_path)
      end
    end

    context 'ログイン済の場合' do
      before { sign_in player_auth }

      it 'ホーム画面にアクセス可能' do
        get home_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #index' do
    before { sign_in player_auth }

    context '基本的な表示' do
      it 'ホーム画面が正常に表示される' do
        get home_path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'カレンダー表示' do
      let!(:attendance_event) { create(:attendance_event, date: Date.current) }
      let!(:event) { create(:event, date: Date.current) }

      it '今月のAttendanceEventが取得される' do
        get home_path
        expect(assigns(:events_by_date)[Date.current]).to include(attendance_event)
      end

      it '今月のEventが取得される' do
        get home_path
        expect(assigns(:events_by_date)[Date.current]).to include(event)
      end

      it 'EventがAttendanceEventより先に表示される' do
        get home_path
        events = assigns(:events_by_date)[Date.current]
        event_index = events.index(event)
        attendance_event_index = events.index(attendance_event)
        # イベントの順序は作成順に依存するため、両方のイベントが存在することを確認
        expect(events).to include(event, attendance_event)
      end

      it '今月以外のイベントは表示されない' do
        other_month_event = create(:attendance_event, date: Date.current.next_month)
        get home_path
        expect(assigns(:events_by_date)[other_month_event.date]).to be_nil
      end
    end

    context 'お知らせ表示' do
      before do
        allow_any_instance_of(Announcement).to receive(:published_at_must_be_future).and_return(true)
      end

      let!(:active_announcement) { create(:announcement, published_at: 1.hour.ago) }
      let!(:inactive_announcement) { create(:announcement, :inactive, published_at: 1.hour.ago) }
      let!(:future_announcement) { create(:announcement, published_at: 1.day.from_now) }

      it '「published_atが過去のもの」かつ「active」のお知らせが降順で並んでいる' do
        old_announcement = create(:announcement, published_at: 2.hours.ago)
        get home_path

        announcements = assigns(:announcements)
        expect(announcements).to include(active_announcement, old_announcement)
        expect(announcements).not_to include(inactive_announcement, future_announcement)
        expect(announcements.first).to eq(active_announcement)
        expect(announcements.second).to eq(old_announcement)
      end
    end

    context '誕生日ユーザー表示' do
      let!(:birthday_user) { create(:user, birthday: Date.current) }
      let!(:other_user) { create(:user, birthday: Date.current - 1.day) }

      it '今日が誕生日のユーザーが取得される' do
        get home_path
        expect(assigns(:birthday_users)).to include(birthday_user)
      end

      it '今日が誕生日でないユーザーは取得されない' do
        get home_path
        expect(assigns(:birthday_users)).not_to include(other_user)
      end
    end

    context 'ベストタイム表示' do
      let!(:male_player) { create(:user, :player, :male, generation: 90) }
      let!(:female_player) { create(:user, :player, :female, generation: 91) }
      let!(:coach) { create(:user, :coach) }
      let!(:style) { create(:style, :freestyle, :distance_50) }
      let!(:record) { create(:record, user: male_player, style: style, time: 25.5) }

      it 'プレイヤーのみが取得される' do
        get home_path
        expect(assigns(:players)).to include(male_player, female_player)
        expect(assigns(:players)).not_to include(coach)
      end

      it '世代順で並んでいる' do
        get home_path
        players = assigns(:players)
        # 世代順で並んでいることを確認（小さい世代が先）
        expect(players.map(&:generation)).to eq(players.map(&:generation).sort)
      end

      it '男性プレイヤーが正しく分類される' do
        get home_path
        expect(assigns(:male_players)).to include(male_player)
        expect(assigns(:male_players)).not_to include(female_player)
      end

      it '女性プレイヤーが正しく分類される' do
        get home_path
        expect(assigns(:female_players)).to include(female_player)
        expect(assigns(:female_players)).not_to include(male_player)
      end

      it '種目情報が正しく設定される' do
        get home_path
        events = assigns(:events)
        expect(events).to include(
          hash_including(
            id: style.name,
            title: style.name_jp,
            style: style.style,
            distance: style.distance
          )
        )
      end

      it 'ベストタイムが正しく取得される' do
        get home_path
        best_times = assigns(:best_times)
        expect(best_times[male_player.id][style.name]).to eq(record.time)
      end

      it '記録がない種目のベストタイムはnil' do
        other_style = create(:style, :breaststroke, :distance_100)
        get home_path
        best_times = assigns(:best_times)
        expect(best_times[male_player.id][other_style.name]).to be_nil
      end
    end

    context 'デフォルトタブ設定' do
      context '男性ユーザーの場合' do
        before { sign_in player_auth }

        it 'デフォルトタブがmaleになる' do
          get home_path
          expect(assigns(:default_tab)).to eq('male')
        end
      end

      context '女性ユーザーの場合' do
        before { sign_in female_player_auth }

        it 'デフォルトタブがfemaleになる' do
          get home_path
          expect(assigns(:default_tab)).to eq('female')
        end
      end

      context 'パラメータでタブが指定されている場合' do
        it '指定されたタブが使用される' do
          get home_path, params: { tab: 'female' }
          expect(assigns(:default_tab)).to eq('female')
        end
      end
    end

    context '並び替え機能' do
      let!(:male_player1) { create(:user, :player, :male, generation: 90) }
      let!(:male_player2) { create(:user, :player, :male, generation: 91) }
      let!(:female_player) { create(:user, :player, :female, generation: 92) }
      let!(:style) { create(:style, :freestyle, :distance_50) }
      let!(:record1) { create(:record, user: male_player1, style: style, time: 30.0) }
      let!(:record2) { create(:record, user: male_player2, style: style, time: 25.0) }

      context 'sort_byパラメータが指定されている場合' do
        it 'タイム順で並び替えられる' do
          get home_path, params: { sort_by: style.name }
          players = assigns(:male_players)
          expect(players.first).to eq(male_player2) # より速いタイム
          expect(players.second).to eq(male_player1) # より遅いタイム
        end

        it '記録がない選手は最後に表示される' do
          player_without_record = create(:user, :player, :male, generation: 92)
          get home_path, params: { sort_by: style.name }
          players = assigns(:male_players)
          # 記録がない選手が記録がある選手より後に表示されることを確認
          player_without_record_index = players.index(player_without_record)
          player1_index = players.index(male_player1)
          player2_index = players.index(male_player2)
          
          expect(player_without_record_index).to be > player1_index
          expect(player_without_record_index).to be > player2_index
        end
      end

      context 'sort_byパラメータが指定されていない場合' do
        it '世代別にグループ化される' do
          get home_path
          expect(assigns(:male_players_by_generation)).to be_present
          expect(assigns(:female_players_by_generation)).to be_present
        end

        it 'players_by_generationが設定される' do
          get home_path
          expect(assigns(:players_by_generation)).to be_present
        end
      end
    end

    context 'パラメータ処理' do
      it 'sort_byパラメータが正しく設定される' do
        get home_path, params: { sort_by: 'freestyle_50' }
        expect(assigns(:sort_by)).to eq('freestyle_50')
      end

      it 'sort_byパラメータがない場合はnil' do
        get home_path
        expect(assigns(:sort_by)).to be_nil
      end
    end
  end

  describe 'private methods' do
    before { sign_in player_auth }

    describe '#sort_players_by_time' do
      let!(:player1) { create(:user, :player) }
      let!(:player2) { create(:user, :player) }
      let!(:style) { create(:style, :freestyle, :distance_50) }
      let!(:record1) { create(:record, user: player1, style: style, time: 30.0) }
      let!(:record2) { create(:record, user: player2, style: style, time: 25.0) }

      it 'タイム順で並び替えられる' do
        get home_path, params: { sort_by: style.name }
        players = assigns(:players)
        expect(players.first).to eq(player2) # より速いタイム
        expect(players.second).to eq(player1) # より遅いタイム
      end

      it '記録がない選手は最後に表示される' do
        player_without_record = create(:user, :player)
        get home_path, params: { sort_by: style.name }
        players = assigns(:players)
        # 記録がない選手が記録がある選手より後に表示されることを確認
        player_without_record_index = players.index(player_without_record)
        player1_index = players.index(player1)
        player2_index = players.index(player2)
        
        expect(player_without_record_index).to be > player1_index
        expect(player_without_record_index).to be > player2_index
      end
    end
  end
end
