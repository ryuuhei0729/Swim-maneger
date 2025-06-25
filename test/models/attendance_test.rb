require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  def setup
    @attendance = attendances(:present_attendance)
  end

  # バリデーションテスト
  test "should be valid with valid attributes" do
    assert @attendance.valid?
  end

  test "should require status" do
    @attendance.status = nil
    assert_not @attendance.valid?
    assert_includes @attendance.errors[:status], "can't be blank"
  end

  test "should require user_id" do
    @attendance.user_id = nil
    assert_not @attendance.valid?
  end

  test "should require attendance_event_id" do
    @attendance.attendance_event_id = nil
    assert_not @attendance.valid?
  end

  test "should enforce uniqueness of user_id scoped to attendance_event_id" do
    duplicate_attendance = @attendance.dup
    assert_not duplicate_attendance.valid?
    assert_includes duplicate_attendance.errors[:user_id], "has already been taken"
  end

  # カスタムバリデーションテスト
  test "should require note for absent status" do
    @attendance.status = "absent"
    @attendance.note = ""
    assert_not @attendance.valid?
    assert_includes @attendance.errors[:note], "required_for_absence_or_other"
  end

  test "should require note for other status" do
    @attendance.status = "other"
    @attendance.note = ""
    assert_not @attendance.valid?
    assert_includes @attendance.errors[:note], "required_for_absence_or_other"
  end

  test "should not require note for present status" do
    @attendance.status = "present"
    @attendance.note = ""
    assert @attendance.valid?
  end

  test "should be valid with note for absent status" do
    @attendance.status = "absent"
    @attendance.note = "体調不良"
    assert @attendance.valid?
  end

  test "should be valid with note for other status" do
    @attendance.status = "other"
    @attendance.note = "遅刻予定"
    assert @attendance.valid?
  end

  # アソシエーションテスト
  test "should belong to user" do
    assert_respond_to @attendance, :user
    assert_equal users(:player), @attendance.user
  end

  test "should belong to attendance_event" do
    assert_respond_to @attendance, :attendance_event
    assert_equal attendance_events(:practice_event), @attendance.attendance_event
  end

  # enumテスト
  test "should have correct status enum values" do
    assert Attendance.statuses.key?("present")
    assert Attendance.statuses.key?("absent")
    assert Attendance.statuses.key?("other")
  end

  test "should have present? method" do
    @attendance.status = "present"
    assert @attendance.present?
    assert_not @attendance.absent?
    assert_not @attendance.other?
  end

  test "should have absent? method" do
    @attendance.status = "absent"
    assert @attendance.absent?
    assert_not @attendance.present?
    assert_not @attendance.other?
  end

  test "should have other? method" do
    @attendance.status = "other"
    assert @attendance.other?
    assert_not @attendance.present?
    assert_not @attendance.absent?
  end

  # データの整合性テスト
  test "fixtures should be valid" do
    Attendance.all.each do |attendance|
      assert attendance.valid?, "#{attendance.id} should be valid"
    end
  end

  # エッジケーステスト
  test "should handle long note text" do
    long_note = "a" * 1000
    @attendance.status = "absent"
    @attendance.note = long_note
    assert @attendance.valid?
  end

  test "should handle special characters in note" do
    special_note = "体調不良のため欠席します。\n明日から復帰予定です。"
    @attendance.status = "absent"
    @attendance.note = special_note
    assert @attendance.valid?
  end
end
