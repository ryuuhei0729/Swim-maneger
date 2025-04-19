# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 時間フォーマット用のヘルパーメソッド
def format_time(seconds)
  seconds = seconds.to_f  # 整数を浮動小数点数に変換
  if seconds < 60
    # 1分未満: 00.00形式
    format("%02d.%02d", seconds / 1, (seconds % 1 * 100).round)
  elsif seconds < 600
    # 1分以上10分未満: 0:00.00形式
    format("%d:%02d.%02d", seconds / 60, (seconds % 60) / 1, ((seconds % 1) * 100).round)
  else
    # 10分以上: 00:00.00形式
    format("%02d:%02d.%02d", seconds / 3600, (seconds % 3600) / 60, ((seconds % 60) / 1).round)
  end
end

# ユーザータイプの定義
USER_TYPES = ['director', 'coach', 'player']
GENDERS = ['male', 'female']

# データベースをクリア
puts "データベースをクリアしています..."
UserAuth.destroy_all
User.destroy_all
BestTimeTable.destroy_all
Announcement.destroy_all
AttendanceEvent.destroy_all
Attendance.destroy_all

# ユーザー作成
puts "Creating users..."

# ディレクター4人作成
4.times do |i|
  user = User.create!(
    generation: 0,
    name: "ディレクター#{i+1}",
    gender: GENDERS.sample,
    birthday: Date.today - rand(30..50).years,
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

# コーチ8人作成
8.times do |i|
  user = User.create!(
    generation: rand(73..77),
    name: "コーチ#{i+1}",
    gender: GENDERS.sample,
    birthday: Date.today - rand(25..45).years,
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

# プレイヤー38人作成
38.times do |i|
  user = User.create!(
    generation: rand(78..84),
    name: "プレイヤー#{i+1}",
    gender: GENDERS.sample,
    birthday: Date.today - rand(18..30).years,
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
    '50m_fr': format_time(rand(20..30) + rand(0..99).to_f / 100),
    '50m_fr_note': rand < 0.3 ? "メモ: #{user.name}の50mフリースタイル記録" : nil,
    '100m_fr': format_time(rand(45..65) + rand(0..99).to_f / 100),
    '100m_fr_note': rand < 0.3 ? "メモ: #{user.name}の100mフリースタイル記録" : nil,
    '200m_fr': format_time(rand(100..120) + rand(0..99).to_f / 100),
    '200m_fr_note': rand < 0.3 ? "メモ: #{user.name}の200mフリースタイル記録" : nil,
    '400m_fr': format_time(rand(240..300) + rand(0..99).to_f / 100),
    '400m_fr_note': rand < 0.3 ? "メモ: #{user.name}の400mフリースタイル記録" : nil,
    '800m_fr': format_time(rand(480..600) + rand(0..99).to_f / 100),
    '800m_fr_note': rand < 0.3 ? "メモ: #{user.name}の800mフリースタイル記録" : nil,

    # バタフライ
    '50m_fly': format_time(rand(25..35) + rand(0..99).to_f / 100),
    '50m_fly_note': rand < 0.3 ? "メモ: #{user.name}の50mバタフライ記録" : nil,
    '100m_fly': format_time(rand(55..75) + rand(0..99).to_f / 100),
    '100m_fly_note': rand < 0.3 ? "メモ: #{user.name}の100mバタフライ記録" : nil,
    '200m_fly': format_time(rand(120..150) + rand(0..99).to_f / 100),
    '200m_fly_note': rand < 0.3 ? "メモ: #{user.name}の200mバタフライ記録" : nil,

    # 背泳ぎ
    '50m_ba': format_time(rand(25..35) + rand(0..99).to_f / 100),
    '50m_ba_note': rand < 0.3 ? "メモ: #{user.name}の50m背泳ぎ記録" : nil,
    '100m_ba': format_time(rand(55..75) + rand(0..99).to_f / 100),
    '100m_ba_note': rand < 0.3 ? "メモ: #{user.name}の100m背泳ぎ記録" : nil,
    '200m_ba': format_time(rand(120..150) + rand(0..99).to_f / 100),
    '200m_ba_note': rand < 0.3 ? "メモ: #{user.name}の200m背泳ぎ記録" : nil,

    # 平泳ぎ
    '50m_br': format_time(rand(30..40) + rand(0..99).to_f / 100),
    '50m_br_note': rand < 0.3 ? "メモ: #{user.name}の50m平泳ぎ記録" : nil,
    '100m_br': format_time(rand(65..85) + rand(0..99).to_f / 100),
    '100m_br_note': rand < 0.3 ? "メモ: #{user.name}の100m平泳ぎ記録" : nil,
    '200m_br': format_time(rand(140..170) + rand(0..99).to_f / 100),
    '200m_br_note': rand < 0.3 ? "メモ: #{user.name}の200m平泳ぎ記録" : nil,

    # 個人メドレー
    '100m_im': format_time(rand(60..80) + rand(0..99).to_f / 100),
    '100m_im_note': rand < 0.3 ? "メモ: #{user.name}の100m個人メドレー記録" : nil,
    '200m_im': format_time(rand(130..150) + rand(0..99).to_f / 100),
    '200m_im_note': rand < 0.3 ? "メモ: #{user.name}の200m個人メドレー記録" : nil,
    '400m_im': format_time(rand(280..320) + rand(0..99).to_f / 100),
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
title = ["朝練", "午前練", "午後練", "大会"]


# 今月のイベント作成
current_month_dates.each do |date|
  # 平日は朝練と夕練
  if (1..5).include?(date.wday)
    # 午前練
    event = AttendanceEvent.create!(
      title: "午前練",
      date: date,
      note: "午前の練習です。全体練習を行います。"
    )
    
    # 午後練
    event = AttendanceEvent.create!(
      title: "午後練",
      date: date,
      note: "午後の練習です。種目別練習を行います。"
    )
  end

  # 土曜日は休日練習
  if date.saturday?
    event = AttendanceEvent.create!(
      title: "休日練習",
      date: date,
      note: "休日の特別練習です。"
    )
  end
end

# 大会を2つ作成
[current_month_dates[10], next_month_dates[5]].each do |date|
  event = AttendanceEvent.create!(
    title: "県大会",
    date: date,
    note: "県大会です。全員参加必須です。"
  )
end

puts "出席イベントの作成が完了しました"

# 出席データの作成
puts "出席データを作成中..."

# プレイヤーユーザーを取得
players = User.where(user_type: 'player')

AttendanceEvent.all.each do |event|
  # ランダムな数のプレイヤーを選択（50%〜90%が出席）
  attending_players = players.sample(rand((players.count * 0.5)..(players.count * 0.9)))
  
  attending_players.each do |player|
    # 出席ステータスをランダムに設定
    status = ["present", "absent", "late"].sample
    
    Attendance.create!(
      user: player,
      attendance_event: event,
      status: status,
      comment: status == "absent" ? "欠席" : nil
    )
  end
end

puts "出席データの作成が完了しました"
