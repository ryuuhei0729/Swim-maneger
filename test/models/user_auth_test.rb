require "test_helper"

class UserAuthTest < ActiveSupport::TestCase
  def setup
    @user_auth = UserAuth.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # バリデーションテスト
  test "should be valid with valid attributes" do
    assert @user_auth.valid?
  end

  test "should require email" do
    @user_auth.email = nil
    assert_not @user_auth.valid?
    assert_includes @user_auth.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @user_auth.email = "invalid-email"
    assert_not @user_auth.valid?
    assert_includes @user_auth.errors[:email], "is invalid"
  end

  test "should require unique email" do
    @user_auth.save!
    duplicate_user_auth = UserAuth.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not duplicate_user_auth.valid?
    assert_includes duplicate_user_auth.errors[:email], "has already been taken"
  end

  test "should require password" do
    @user_auth.password = nil
    assert_not @user_auth.valid?
    assert_includes @user_auth.errors[:password], "can't be blank"
  end

  test "should require minimum password length" do
    @user_auth.password = "123"
    @user_auth.password_confirmation = "123"
    assert_not @user_auth.valid?
    assert_includes @user_auth.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "should require password confirmation" do
    @user_auth.password_confirmation = "different_password"
    assert_not @user_auth.valid?
    assert_includes @user_auth.errors[:password_confirmation], "doesn't match Password"
  end

  # アソシエーションテスト
  test "should belong to user" do
    assert_respond_to @user_auth, :user
  end

  # メソッドテスト
  test "profile_image_url should return gravatar url" do
    expected_url = "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('test@example.com'.downcase)}?s=200&d=identicon"
    assert_equal expected_url, @user_auth.profile_image_url
  end

  # Devise機能のテスト
  test "should be database authenticatable" do
    @user_auth.save!
    assert UserAuth.find_for_authentication(email: "test@example.com")
  end

  test "should be registerable" do
    assert @user_auth.save
    assert @user_auth.persisted?
  end

  test "should be recoverable" do
    assert_respond_to @user_auth, :send_reset_password_instructions
  end

  test "should be rememberable" do
    assert_respond_to @user_auth, :remember_me!
  end

  # コールバックテスト
  test "should build default user on create when user is not present" do
    @user_auth.save!
    assert @user_auth.user.present?
    assert_equal "test", @user_auth.user.name
    assert_equal 1, @user_auth.user.generation
    assert_equal "male", @user_auth.user.gender
    assert_equal "player", @user_auth.user.user_type
  end

  test "should not build default user when user is already present" do
    existing_user = User.create!(
      name: "Existing User",
      generation: 2020,
      gender: "female",
      birthday: Date.new(2008, 4, 1),
      user_type: "coach"
    )
    @user_auth.user = existing_user
    @user_auth.save!
    
    assert_equal existing_user, @user_auth.user
    assert_equal "Existing User", @user_auth.user.name
    assert_equal "coach", @user_auth.user.user_type
  end

  # エッジケーステスト
  test "should handle email with special characters in profile_image_url" do
    @user_auth.email = "test+tag@example.com"
    expected_url = "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('test+tag@example.com'.downcase)}?s=200&d=identicon"
    assert_equal expected_url, @user_auth.profile_image_url
  end

  test "should handle empty email in profile_image_url" do
    @user_auth.email = ""
    expected_url = "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(''.downcase)}?s=200&d=identicon"
    assert_equal expected_url, @user_auth.profile_image_url
  end
end 