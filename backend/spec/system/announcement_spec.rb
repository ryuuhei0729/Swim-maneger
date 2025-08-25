require 'rails_helper'

RSpec.describe 'お知らせ機能', type: :system do
  let(:coach_user) { create(:user, :coach) }
  let(:coach_auth) { create(:user_auth, user: coach_user) }
  let(:player_user) { create(:user, :player) }
  let(:player_auth) { create(:user_auth, user: player_user) }

  before do
    driven_by(:rack_test)
  end

  describe 'CRUD操作' do
    context '新規お知らせを作成する場合' do
      it '管理者がお知らせを作成し、プレイヤーが閲覧できること' do
        # 管理者でログイン
        login_as_admin

        # 管理者画面に移動
        visit admin_path
        expect(page).to have_content('管理者画面')

        # お知らせ管理ページに移動
        click_link 'お知らせ管理'
        expect(current_path).to eq('/admin/announcement')

        # 新規お知らせを作成
        fill_in 'announcement[title]', with: 'テストお知らせ'
        fill_in 'announcement[content]', with: 'これはテスト用のお知らせです。'
        check 'announcement[is_active]'
        fill_in 'announcement[published_at]', with: Time.current.strftime("%Y-%m-%dT%H:%M")
        click_button '作成'

        # 作成成功の確認
        expect(page).to have_content('お知らせを作成しました。')
        expect(page).to have_content('テストお知らせ')
        expect(page).to have_content('これはテスト用のお知らせです。')

        # ログアウト
        logout

        # プレイヤーでログイン
        login_as_player

        # Homeページでお知らせが表示されていることを確認
        expect(page).to have_content('お知らせ')
        expect(page).to have_content('テストお知らせ')
        expect(page).to have_content('これはテスト用のお知らせです。')
      end
    end

    context 'お知らせを編集する場合' do
      let!(:announcement) { create(:announcement, title: '編集前のお知らせ', content: '編集前の内容') }

      it '管理者がお知らせを編集し、プレイヤーが更新された内容を閲覧できること' do
        # 管理者でログイン
        login_as_admin

        # お知らせ管理ページに移動
        visit admin_announcement_path
        expect(current_path).to eq('/admin/announcement')

        # お知らせ一覧に編集前のお知らせが表示されていることを確認
        expect(page).to have_content('編集前のお知らせ')
        expect(page).to have_content('編集前の内容')

        # お知らせを編集
        click_button '編集'
        
        # モーダルが開くことを確認
        expect(page).to have_content('お知らせの編集')
        
        # フォームを編集（モーダル内のフォームを特定）
        within('[data-controller="modal"]') do
          fill_in 'announcement[title]', with: '編集後のお知らせ'
          fill_in 'announcement[content]', with: '編集後の内容です。'
          check 'announcement[is_active]'
          fill_in 'announcement[published_at]', with: Time.current.strftime("%Y-%m-%dT%H:%M")
          click_button '更新'
        end

        # 編集成功の確認
        expect(page).to have_content('お知らせを更新しました。')
        expect(page).to have_content('編集後のお知らせ')
        expect(page).to have_content('編集後の内容です。')

        # ログアウト
        logout

        # プレイヤーでログイン
        login_as_player

        # Homeページで編集後のお知らせが表示されていることを確認
        expect(page).to have_content('お知らせ')
        expect(page).to have_content('編集後のお知らせ')
        expect(page).to have_content('編集後の内容です。')

        # 編集前の内容が表示されていないことを確認
        expect(page).not_to have_content('編集前のお知らせ')
        expect(page).not_to have_content('編集前の内容')
      end
    end

    context 'お知らせを削除する場合' do
      let!(:announcement) { create(:announcement, title: '削除対象のお知らせ', content: '削除対象の内容') }

      it '管理者がお知らせを削除し、プレイヤーが削除された内容を閲覧できないこと' do
        # 管理者でログイン
        visit new_user_auth_session_path
        fill_in 'user_auth[email]', with: coach_auth.email
        fill_in 'user_auth[password]', with: 'password123'
        click_button 'ログイン'

        expect(page).to have_content('ログインしました。')

        # お知らせ管理ページに移動
        visit admin_announcement_path
        expect(current_path).to eq('/admin/announcement')

        # お知らせ一覧に削除対象のお知らせが表示されていることを確認
        expect(page).to have_content('削除対象のお知らせ')
        expect(page).to have_content('削除対象の内容')

        # お知らせを削除
        click_button '削除'

        # 削除成功の確認
        expect(page).to have_content('お知らせを削除しました。')
        expect(page).not_to have_content('削除対象のお知らせ')
        expect(page).not_to have_content('削除対象の内容')

        # ログアウト
        logout

        # プレイヤーでログイン
        login_as_player

        # Homeページで削除されたお知らせが表示されていないことを確認
        expect(page).to have_content('お知らせ')
        expect(page).not_to have_content('削除対象のお知らせ')
        expect(page).not_to have_content('削除対象の内容')

        # お知らせがない場合のメッセージが表示されることを確認
        expect(page).to have_content('お知らせはまだありません')
      end
    end
  end

  describe '表示制御' do
    context 'お知らせが非公開の場合' do
      let!(:inactive_announcement) { create(:announcement, :inactive, title: '非公開のお知らせ', content: '非公開の内容') }

      it 'プレイヤーに非公開のお知らせが表示されないこと' do
        # プレイヤーでログイン
        login_as_player

        # Homeページに移動
        visit home_path

        # 非公開のお知らせが表示されていないことを確認
        expect(page).not_to have_content('非公開のお知らせ')
        expect(page).not_to have_content('非公開の内容')
      end
    end

    context 'お知らせが未来の公開日時の場合' do
      let!(:future_announcement) { create(:announcement, :future, title: '未来のお知らせ', content: '未来の内容') }

      it 'プレイヤーに未来のお知らせが表示されないこと' do
        # プレイヤーでログイン
        login_as_player

        # Homeページに移動
        visit home_path

        # 未来のお知らせが表示されていないことを確認
        expect(page).not_to have_content('未来のお知らせ')
        expect(page).not_to have_content('未来の内容')
      end
    end
  end

  describe 'バリデーション' do
    context '無効なデータの場合' do
      it 'タイトルが空の場合にエラーメッセージが表示されること' do
        # 管理者でログイン
        login_as_admin

        # お知らせ管理ページに移動
        visit admin_announcement_path

        # 無効なデータでお知らせを作成
        fill_in 'announcement[title]', with: ''
        fill_in 'announcement[content]', with: '内容'
        check 'announcement[is_active]'
        fill_in 'announcement[published_at]', with: Time.current.strftime("%Y-%m-%dT%H:%M")
        click_button '作成'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('タイトル を入力してください')
      end

      it '内容が空の場合にエラーメッセージが表示されること' do
        # 管理者でログイン
        login_as_admin

        # お知らせ管理ページに移動
        visit admin_announcement_path

        # 無効なデータでお知らせを作成
        fill_in 'announcement[title]', with: 'タイトル'
        fill_in 'announcement[content]', with: ''
        check 'announcement[is_active]'
        fill_in 'announcement[published_at]', with: Time.current.strftime("%Y-%m-%dT%H:%M")
        click_button '作成'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('内容 を入力してください')
      end
    end
  end
end 