require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  let(:user) { create(:user_auth, email: 'test@example.com', password: '123123') }

  before do
    driven_by(:rack_test)
  end

  describe 'ログイン機能' do
    before do
      visit new_user_auth_session_path
    end

    context 'ログイン成功' do
      it 'メールアドレスとパスワードを入力することでログインが成功すること' do
        fill_in 'user_auth[email]', with: user.email
        fill_in 'user_auth[password]', with: '123123'
        click_button 'ログイン'

        expect(page).to have_content('ログインしました。')
        expect(current_path).to eq('/home')
      end
    end

    context 'ログイン失敗' do
      it '無効なメールアドレスでログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: 'invalid-email'
        fill_in 'user_auth[password]', with: '123123'
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'パスワードが間違っているとログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: user.email
        fill_in 'user_auth[password]', with: 'wrongpassword'
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'メールアドレスが間違っているとログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: 'wrong@example.com'
        fill_in 'user_auth[password]', with: '123123'
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'メールアドレスが空の場合、ログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: ''
        fill_in 'user_auth[password]', with: '123123'
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'パスワードが空の場合、ログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: user.email
        fill_in 'user_auth[password]', with: ''
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end
    end
  end

  describe 'ログアウト機能' do
    before do
      # ログインする
      visit new_user_auth_session_path
      fill_in 'user_auth[email]', with: user.email
      fill_in 'user_auth[password]', with: '123123'
      click_button 'ログイン'
    end

    context 'ログアウト成功' do
      it 'ログアウトボタンをクリックすることでログアウトが成功すること' do
        # ログイン後のページにいることを確認
        expect(current_path).to eq('/home')
        
        # ログアウトボタンをクリック
        click_button 'ログアウト'
        
        # ログアウト後の確認
        expect(page).to have_content('ログアウトしました。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'ログアウト後にログイン画面にリダイレクトされること' do
        click_button 'ログアウト'
        
        # ログイン画面にいることを確認
        expect(current_path).to eq(new_user_auth_session_path)
        expect(page).to have_content('ログイン')
      end

      it 'ログアウト後に保護されたページにアクセスできないこと' do
        click_button 'ログアウト'
        
        # 保護されたページにアクセス
        visit home_path
        
        # ログイン画面にリダイレクトされることを確認
        expect(current_path).to eq(new_user_auth_session_path)
      end
    end
  end
end 