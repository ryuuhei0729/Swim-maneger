require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  let(:user) { create(:user_auth, email: 'test@example.com', password: 'password123') }

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
        fill_in 'user_auth[password]', with: 'password123'
        click_button 'ログイン'

        expect(page).to have_content('ログインしました。')
        expect(current_path).to eq('/home')
      end
    end

    context 'ログイン失敗' do
      it '無効なメールアドレスでログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: 'invalid-email'
        fill_in 'user_auth[password]', with: 'password123'
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
        fill_in 'user_auth[password]', with: 'password123'
        click_button 'ログイン'

        expect(page).to have_content('メールアドレスまたはパスワードが違います。')
        expect(current_path).to eq(new_user_auth_session_path)
      end

      it 'メールアドレスが空の場合、ログインに失敗し、エラーメッセージが表示されること' do
        fill_in 'user_auth[email]', with: ''
        fill_in 'user_auth[password]', with: 'password123'
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

  describe '管理者ページへのアクセス権限' do
    before do
      # playerとしてログイン
      login_as_player
    end

    context 'admin/以下のURLにアクセスした場合' do
      it 'admin/にアクセスすると権限エラーでリダイレクトされること' do
        visit admin_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/usersにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_users_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/users/newにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_create_user_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/users/importにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_users_import_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/users/import/templateにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_users_import_template_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/objectiveにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_objective_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/announcementにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_announcement_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/scheduleにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_schedule_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/schedule/importにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_schedule_import_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/schedule/import/templateにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_schedule_import_template_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/practiceにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_practice_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/practice/timeにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_practice_time_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/practice/time/inputにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_practice_time_input_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/practice/registerにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_practice_register_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/attendanceにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_attendance_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/attendance/checkにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_attendance_check_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/attendance/statusにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_attendance_status_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/attendance/updateにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_attendance_update_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end

      it 'admin/competitionにアクセスすると権限エラーでリダイレクトされること' do
        visit admin_competition_path
        expect(page).to have_content('このページにアクセスする権限がありません。')
        expect(current_path).to eq('/home')
      end
    end
  end
end
