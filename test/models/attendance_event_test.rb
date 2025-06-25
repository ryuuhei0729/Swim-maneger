require "test_helper"

class AttendanceEventTest < ActiveSupport::TestCase
  def setup
    @attendance_event = attendance_events(:practice_event)
  end

  # バリデーションテスト
  test "should be valid with valid attributes" do
    assert @attendance_event.valid?
  end

  test "should require title" do
    @attendance_event.title = nil
    assert_not @attendance_event.valid?
    assert_includes @attendance_event.errors[:title], "can't be blank"
  end

  test "should require date" do
    @attendance_event.date = nil
    assert_not @attendance_event.valid?
    assert_includes @attendance_event.errors[:date], "can't be blank"
  end

  test "should validate is_competition inclusion" do
    @attendance_event.is_competition = nil
    assert_not @attendance_event.valid?
    assert_includes @attendance_event.errors[:is_competition], "is not included in the list"
  end

  test "should accept true for is_competition" do
    @attendance_event.is_competition = true
    assert @attendance_event.valid?
  end

  test "should accept false for is_competition" do
    @attendance_event.is_competition = false
    assert @attendance_event.valid?
  end

  # アソシエーションテスト
  test "should have many attendance" do
    assert_respond_to @attendance_event, :attendance
  end

  test "should have many users through attendance" do
    assert_respond_to @attendance_event, :users
  end

  test "should have many records" do
    assert_respond_to @attendance_event, :records
  end

  test "should have many objectives" do
    assert_respond_to @attendance_event, :objectives
  end

  test "should have many race_goals" do
    assert_respond_to @attendance_event, :race_goals
  end

  test "should have one attached menu_image" do
    assert_respond_to @attendance_event, :menu_image
  end

  # スコープテスト
  test "competitions scope should return only competition events" do
    # テスト用に競技会イベントを作成
    competition_event = AttendanceEvent.create!(
      title: "県大会",
      date: Date.today + 1.week,
      is_competition: true
    )
    
    practice_event = AttendanceEvent.create!(
      title: "練習",
      date: Date.today + 2.days,
      is_competition: false
    )

    competitions = AttendanceEvent.competitions
    assert_includes competitions, competition_event
    assert_not_includes competitions, practice_event
  end

  test "upcoming scope should return only future events" do
    future_event = AttendanceEvent.create!(
      title: "未来のイベント",
      date: Date.today + 1.week,
      is_competition: false
    )
    
    past_event = AttendanceEvent.create!(
      title: "過去のイベント",
      date: Date.today - 1.week,
      is_competition: false
    )

    upcoming_events = AttendanceEvent.upcoming
    assert_includes upcoming_events, future_event
    assert_not_includes upcoming_events, past_event
  end

  test "past scope should return only past events" do
    future_event = AttendanceEvent.create!(
      title: "未来のイベント",
      date: Date.today + 1.week,
      is_competition: false
    )
    
    past_event = AttendanceEvent.create!(
      title: "過去のイベント",
      date: Date.today - 1.week,
      is_competition: false
    )

    past_events = AttendanceEvent.past
    assert_includes past_events, past_event
    assert_not_includes past_events, future_event
  end

  test "future scope should return upcoming competitions ordered by date" do
    competition1 = AttendanceEvent.create!(
      title: "県大会",
      date: Date.today + 2.weeks,
      is_competition: true
    )
    
    competition2 = AttendanceEvent.create!(
      title: "全国大会",
      date: Date.today + 1.week,
      is_competition: true
    )
    
    practice_event = AttendanceEvent.create!(
      title: "練習",
      date: Date.today + 3.days,
      is_competition: false
    )

    future_competitions = AttendanceEvent.future
    assert_equal [competition2, competition1], future_competitions.to_a
    assert_not_includes future_competitions, practice_event
  end

  # データの整合性テスト
  test "fixtures should be valid" do
    AttendanceEvent.all.each do |event|
      assert event.valid?, "#{event.title} should be valid"
    end
  end

  # エッジケーステスト
  test "should handle empty title" do
    @attendance_event.title = ""
    assert_not @attendance_event.valid?
  end

  test "should handle very long title" do
    @attendance_event.title = "a" * 1000
    assert @attendance_event.valid?
  end

  test "should handle special characters in title" do
    @attendance_event.title = "練習会（特別）"
    assert @attendance_event.valid?
  end

  test "should handle note with special characters" do
    @attendance_event.note = "練習内容：\n- クロール\n- 平泳ぎ\n- バタフライ"
    assert @attendance_event.valid?
  end
end
