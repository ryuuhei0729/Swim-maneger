module SystemHelpers
  # ユーザー認証情報を作成するヘルパー
  def create_user_with_auth(user_type = :player, email = nil, password = 'password123')
    user = create(:user, user_type)
    user_auth = create(:user_auth, user: user, email: email || "#{user_type}_#{SecureRandom.hex(4)}@example.com", password: password)
    [user, user_auth]
  end

  # 管理者ユーザーを作成するヘルパー
  def create_admin_user
    create_user_with_auth(:coach)
  end

  # プレイヤーユーザーを作成するヘルパー
  def create_player_user
    create_user_with_auth(:player)
  end

  # ログイン処理
  def login_as(user_auth)
    visit new_user_auth_session_path
    fill_in 'user_auth[email]', with: user_auth.email
    fill_in 'user_auth[password]', with: 'password123'
    click_button 'ログイン'
    
    expect(page).to have_content('ログインしました。')
    expect(current_path).to eq('/home')
  end

  # 管理者としてログイン
  def login_as_admin
    user, user_auth = create_admin_user
    login_as(user_auth)
    [user, user_auth]
  end

  # プレイヤーとしてログイン
  def login_as_player
    user, user_auth = create_player_user
    login_as(user_auth)
    [user, user_auth]
  end

  # ログアウト処理
  def logout
    click_on 'ログアウト'
    # ログアウト後にページを再読み込み
    visit current_path
    expect(page).to have_content('ログアウトしました。')
    expect(current_path).to eq(new_user_auth_session_path)
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end 