# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# タイムを表示用の文字列にフォーマットする（83.45秒 → "1:23.45"）
def format_time(seconds)
  return "-" if seconds.nil? || seconds.zero?

  minutes = (seconds / 60).floor
  remaining_seconds = (seconds % 60).round(2)
  
  if minutes.zero?
    format("%05.2f", remaining_seconds)
  else
    format("%d:%05.2f", minutes, remaining_seconds)
  end
end

# 表示用文字列をDECIMAL型の秒数に変換する（"1:23.45" → 83.45）
def parse_time(time_str)
  return 0 if time_str.nil? || time_str == "-"

  if time_str.include?(":")
    minutes, seconds = time_str.split(":")
    minutes.to_i * 60 + seconds.to_f
  else
    time_str.to_f
  end
end

# ランダムなタイムを生成（種目に応じた適切な範囲で）
def generate_random_time(event)
  case event
  when /50m/
    rand(22.00..35.00).round(2)  # 50m: 22-35秒
  when /100m/
    rand(50.00..80.00).round(2)  # 100m: 50-80秒
  when /200m/
    rand(110.00..180.00).round(2) # 200m: 1:50-3:00
  when /400m/
    rand(240.00..360.00).round(2) # 400m: 4:00-6:00
  when /800m/
    rand(480.00..720.00).round(2) # 800m: 8:00-12:00
  else
    0
  end
end

# ユーザータイプの定義
USER_TYPES = ['director', 'coach', 'player', 'manager']
GENDERS = ['male', 'female', 'other']

# データベースをクリア
puts "データベースをクリアしています..."
# Attendance.destroy_all
# AttendanceEvent.destroy_all
# BestTimeTable.destroy_all
# Announcement.destroy_all
# User.destroy_all
# UserAuth.destroy_all

# ユーザー作成
puts "Creating users..."

# ディレクター4人作成
4.times do |i|
  birthday = Date.new(
    rand(1970..1998), # 年
    rand(1..12),      # 月
    rand(1..28)       # 日（28日までにしておくと安全）
  )
  user = User.create!(
    generation: 0,
    name: "ディレクター#{i+1}",
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'director',
    bio: "ディレクター#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "director#{i+1}@test",
    password: "123123",
    password_confirmation: "123123",
    user: user
  )
  
  puts "Created director: #{user.name}"
end

# コーチ6人作成
6.times do |i|
  birthday = Date.new(
    rand(2002..2006),
    rand(1..12),
    rand(1..28)
  )
  user = User.create!(
    generation: rand(73..77),
    name: "コーチ#{i+1}",
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'coach',
    bio: "コーチ#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "coach#{i+1}@test",
    password: "123123",
    password_confirmation: "123123",
    user: user
  )
  
  puts "Created coach: #{user.name}"
end

# プレイヤー30人作成
30.times do |i|
  birthday = Date.new(
    rand(2007..2012),
    rand(1..12),
    rand(1..28)
  )
  user = User.create!(
    generation: rand(78..84),
    name: "プレイヤー#{i+1}",
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'player',
    bio: "プレイヤー#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "player#{i+1}@test",
    password: "123123",
    password_confirmation: "123123",
    user: user
  )
  
  puts "Created player: #{user.name}"
end

# ベストタイムテーブル作成（プレイヤーのみ）
puts "Creating best time tables for players..."

User.where(user_type: 'player').each do |user|
  best_time = BestTimeTable.create!(
    user: user,
    # フリースタイル
    '50m_fr': generate_random_time("50m"),
    '50m_fr_note': rand < 0.3 ? "メモ: #{user.name}の50mフリースタイル記録" : nil,
    '100m_fr': generate_random_time("100m"),
    '100m_fr_note': rand < 0.3 ? "メモ: #{user.name}の100mフリースタイル記録" : nil,
    '200m_fr': generate_random_time("200m"),
    '200m_fr_note': rand < 0.3 ? "メモ: #{user.name}の200mフリースタイル記録" : nil,
    '400m_fr': generate_random_time("400m"),
    '400m_fr_note': rand < 0.3 ? "メモ: #{user.name}の400mフリースタイル記録" : nil,
    '800m_fr': generate_random_time("800m"),
    '800m_fr_note': rand < 0.3 ? "メモ: #{user.name}の800mフリースタイル記録" : nil,

    # バタフライ
    '50m_fly': generate_random_time("50m"),
    '50m_fly_note': rand < 0.3 ? "メモ: #{user.name}の50mバタフライ記録" : nil,
    '100m_fly': generate_random_time("100m"),
    '100m_fly_note': rand < 0.3 ? "メモ: #{user.name}の100mバタフライ記録" : nil,
    '200m_fly': generate_random_time("200m"),
    '200m_fly_note': rand < 0.3 ? "メモ: #{user.name}の200mバタフライ記録" : nil,

    # 背泳ぎ
    '50m_ba': generate_random_time("50m"),
    '50m_ba_note': rand < 0.3 ? "メモ: #{user.name}の50m背泳ぎ記録" : nil,
    '100m_ba': generate_random_time("100m"),
    '100m_ba_note': rand < 0.3 ? "メモ: #{user.name}の100m背泳ぎ記録" : nil,
    '200m_ba': generate_random_time("200m"),
    '200m_ba_note': rand < 0.3 ? "メモ: #{user.name}の200m背泳ぎ記録" : nil,

    # 平泳ぎ
    '50m_br': generate_random_time("50m"),
    '50m_br_note': rand < 0.3 ? "メモ: #{user.name}の50m平泳ぎ記録" : nil,
    '100m_br': generate_random_time("100m"),
    '100m_br_note': rand < 0.3 ? "メモ: #{user.name}の100m平泳ぎ記録" : nil,
    '200m_br': generate_random_time("200m"),
    '200m_br_note': rand < 0.3 ? "メモ: #{user.name}の200m平泳ぎ記録" : nil,

    # 個人メドレー
    '100m_im': generate_random_time("100m"),
    '100m_im_note': rand < 0.3 ? "メモ: #{user.name}の100m個人メドレー記録" : nil,
    '200m_im': generate_random_time("200m"),
    '200m_im_note': rand < 0.3 ? "メモ: #{user.name}の200m個人メドレー記録" : nil,
    '400m_im': generate_random_time("400m"),
    '400m_im_note': rand < 0.3 ? "メモ: #{user.name}の400m個人メドレー記録" : nil
  )
end

puts "テストデータの作成が完了しました。"
puts "作成されたユーザー数: #{User.count}"
puts "作成されたベストタイム数: #{BestTimeTable.count}"

# ユーザーが既に存在することを前提とします

# 出席イベントの作成
puts "出席イベントを作成中..."

# 今月と来月の日付を生成
current_month_dates = (Date.current.beginning_of_month..Date.current.end_of_month).to_a
next_month_dates = (Date.current.next_month.beginning_of_month..Date.current.next_month.end_of_month).to_a

# タイトル
titles = ["陸トレ", "水泳練", "MTG", "大会"]

# 今月のイベント作成
current_month_dates.each do |date|
  case date.wday
  when 1 # 月曜日
    if rand < 0.8 # 80%の確率で
      AttendanceEvent.create!(
        title: "陸トレ",
        date: date,
        place: '小石川5階',
        note: "陸上の練習です。基礎体力向上を目指します。",
        is_competition: false
      )
    end
  when 2 # 火曜日
    if rand < 0.9 # 90%の確率で
      AttendanceEvent.create!(
        title: "水泳練",
        date: date,
        place: 'コズミック',
        note: "水泳の練習です。フォーム改善に重点を置きます。",
        is_competition: false
      )
    end
  when 3 # 水曜日
    if rand < 0.7 # 70%の確率で
      AttendanceEvent.create!(
        title: "全体MTG",
        date: date,
        place: 'オンライン',
        note: "今週の予定と目標の確認を行います。",
        is_competition: false
      )
    end
  when 4 # 木曜日
    if rand < 0.85 # 85%の確率で
      AttendanceEvent.create!(
        title: "水泳練",
        date: date,
        place: 'コズミック',
        note: "水泳の練習です。スピード練習を行います。",
        is_competition: false
      )
    end
  when 5 # 金曜日
    if rand < 0.75 # 75%の確率で
      AttendanceEvent.create!(
        title: "陸トレ",
        date: date,
        place: '小石川5階',
        note: "陸上の練習です。筋力トレーニングを行います。",
        is_competition: false
      )
    end
  when 6 # 土曜日
    if rand < 0.6 # 60%の確率で
      AttendanceEvent.create!(
        title: ["水泳練", "合同練習"].sample,
        date: date,
        place: 'Bumb',
        note: "週末練習です。実践的な練習を行います。",
        is_competition: false
      )
    end
  end
end

# 大会を2つ作成（土日に設定）
current_month_weekends = current_month_dates.select { |d| [6, 0].include?(d.wday) }
next_month_weekends = next_month_dates.select { |d| [6, 0].include?(d.wday) }

[current_month_weekends.sample, next_month_weekends.sample].each do |date|
  AttendanceEvent.create!(
    title: "大会",
    date: date,
    place: 'アクアティクスセンター',
    note: "大会です。全員参加必須です。応援も含めてチーム一丸となって頑張りましょう。",
    is_competition: true
  )
end

puts "出席イベントの作成が完了しました"

# 出席データの作成
puts "出席データを作成中..."

reasons_absent = ["体調不良", "家庭の事情", "学業の都合", "用事があるため", "怪我のため"]
reasons_late = ["電車遅延", "寝坊", "授業が長引いた", "バスが遅れた", "準備に時間がかかった"]

AttendanceEvent.all.each do |event|
  User.all.each do |user|
    # 50%〜90%の確率で出席データを作成
    next unless rand < rand(0.5..0.9)
    status = [:present, :absent, :late].sample
    note =
      case status
      when :absent
        reasons_absent.sample
      when :late
        reasons_late.sample
      else
        nil
      end

    Attendance.create!(
      user: user,
      attendance_event: event,
      status: status,
      note: note
    )
  end
end

puts "出席データの作成が完了しました"
