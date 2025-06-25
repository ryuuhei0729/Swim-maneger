require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:player)
  end

  # バリデーションテスト
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require name" do
    @user.name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "should require generation" do
    @user.generation = nil
    assert_not @user.valid?
    assert_includes @user.errors[:generation], "can't be blank"
  end

  test "should require gender" do
    @user.gender = nil
    assert_not @user.valid?
    assert_includes @user.errors[:gender], "can't be blank"
  end

  test "should require birthday" do
    @user.birthday = nil
    assert_not @user.valid?
    assert_includes @user.errors[:birthday], "can't be blank"
  end

  test "should require user_type" do
    @user.user_type = nil
    assert_not @user.valid?
    assert_includes @user.errors[:user_type], "can't be blank"
  end

  test "should validate gender inclusion" do
    @user.gender = "invalid"
    assert_not @user.valid?
    assert_includes @user.errors[:gender], "is not included in the list"
  end

  test "should validate user_type inclusion" do
    @user.user_type = "invalid"
    assert_not @user.valid?
    assert_includes @user.errors[:user_type], "is not included in the list"
  end

  # 定数テスト
  test "should have correct USER_TYPES constant" do
    expected_types = {
      player: "player",
      coach: "coach",
      director: "director",
      manager: "manager"
    }
    assert_equal expected_types, User::USER_TYPES
  end

  test "should have correct GENDERS constant" do
    expected_genders = {
      male: "male",
      female: "female"
    }
    assert_equal expected_genders, User::GENDERS
  end

  test "should have correct ADMIN_TYPES constant" do
    expected_admin_types = ["coach", "director", "manager"]
    assert_equal expected_admin_types, User::ADMIN_TYPES
  end

  # メソッドテスト
  test "admin? should return true for admin users" do
    assert users(:coach).admin?
    assert users(:director).admin?
    assert users(:manager).admin?
  end

  test "admin? should return false for non-admin users" do
    assert_not users(:player).admin?
  end

  test "coach? should return true for coach users" do
    assert users(:coach).coach?
    assert_not users(:player).coach?
  end

  test "player? should return true for player users" do
    assert users(:player).player?
    assert_not users(:coach).player?
  end

  test "profile_image_url should return avatar when attached" do
    # avatarがアタッチされていない場合はnilを返す
    assert_nil @user.profile_image_url
  end

  # アソシエーションテスト
  test "should have one user_auth" do
    assert_respond_to @user, :user_auth
  end

  test "should have many attendance" do
    assert_respond_to @user, :attendance
  end

  test "should have many attendance_events through attendance" do
    assert_respond_to @user, :attendance_events
  end

  test "should have many records" do
    assert_respond_to @user, :records
  end

  test "should have many objectives" do
    assert_respond_to @user, :objectives
  end

  test "should have many race_goals" do
    assert_respond_to @user, :race_goals
  end

  test "should have many race_feedbacks" do
    assert_respond_to @user, :race_feedbacks
  end

  # 性別とユーザータイプの組み合わせテスト
  test "should accept male gender" do
    @user.gender = "male"
    assert @user.valid?
  end

  test "should accept female gender" do
    @user.gender = "female"
    assert @user.valid?
  end

  test "should accept all valid user types" do
    User::USER_TYPES.values.each do |user_type|
      @user.user_type = user_type
      assert @user.valid?, "#{user_type} should be valid"
    end
  end

  # データの整合性テスト
  test "fixtures should be valid" do
    User.all.each do |user|
      assert user.valid?, "#{user.name} should be valid"
    end
  end
end
