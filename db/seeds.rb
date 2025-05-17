# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'ffaker'
FFaker::NameJA.unique.clear # 一意の名前生成をリセット

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
GENDERS = ['male', 'female']

# データベースをクリア
puts "データベースをクリアしています..."
RaceFeedback.destroy_all rescue nil
RaceReview.destroy_all rescue nil
RaceGoal.destroy_all rescue nil
MilestoneReview.destroy_all rescue nil
Milestone.destroy_all rescue nil
Objective.destroy_all rescue nil
Attendance.destroy_all rescue nil
Record.destroy_all rescue nil
AttendanceEvent.destroy_all rescue nil
UserAuth.destroy_all rescue nil
User.destroy_all rescue nil
Style.destroy_all rescue nil

# 種目の作成
puts "種目を作成中..."
styles = [
  { name_jp: "50m自由形", name: "50Fr", style: "fr", distance: 50 },
  { name_jp: "100m自由形", name: "100Fr", style: "fr", distance: 100 },
  { name_jp: "200m自由形", name: "200Fr", style: "fr", distance: 200 },
  { name_jp: "400m自由形", name: "400Fr", style: "fr", distance: 400 },
  { name_jp: "800m自由形", name: "800Fr", style: "fr", distance: 800 },
  { name_jp: "50m平泳ぎ", name: "50Br", style: "br", distance: 50 },
  { name_jp: "100m平泳ぎ", name: "100Br", style: "br", distance: 100 },
  { name_jp: "200m平泳ぎ", name: "200Br", style: "br", distance: 200 },
  { name_jp: "50m背泳ぎ", name: "50Ba", style: "ba", distance: 50 },
  { name_jp: "100m背泳ぎ", name: "100Ba", style: "ba", distance: 100 },
  { name_jp: "200m背泳ぎ", name: "200Ba", style: "ba", distance: 200 },
  { name_jp: "50mバタフライ", name: "50Fly", style: "fly", distance: 50 },
  { name_jp: "100mバタフライ", name: "100Fly", style: "fly", distance: 100 },
  { name_jp: "200mバタフライ", name: "200Fly", style: "fly", distance: 200 },
  { name_jp: "100m個人メドレー", name: "100IM", style: "im", distance: 100 },
  { name_jp: "200m個人メドレー", name: "200IM", style: "im", distance: 200 },
  { name_jp: "400m個人メドレー", name: "400IM", style: "im", distance: 400 }
]

styles.each do |style_data|
  Style.create!(style_data)
  puts "Created style: #{style_data[:name_jp]}"
end

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
    name: FFaker::NameJA.name,
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'director',
    bio: "ディレクター#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "director#{i+1}@test",
    password: "123123",
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
    name: FFaker::NameJA.name,
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'coach',
    bio: "コーチ#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "coach#{i+1}@test",
    password: "123123",
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
    name: FFaker::NameJA.name,
    gender: GENDERS.sample,
    birthday: birthday,
    user_type: 'player',
    bio: "プレイヤー#{i+1}の自己紹介文です。",
  )
  
  # UserAuthの作成と紐付け
  UserAuth.create!(
    email: "player#{i+1}@test",
    password: "123123",
    user: user
  )
  
  puts "Created player: #{user.name}"
end

# 記録の作成
puts "Creating records..."

# プレイヤーと種目の組み合わせで記録を作成
User.where(user_type: 'player').each do |user|
  Style.all.each do |style|
    # 種目に応じたランダムなタイムを生成
    time = case style.distance
    when 50
      rand(22.00..35.00).round(2)  # 50m: 22-35秒
    when 100
      rand(50.00..80.00).round(2)  # 100m: 50-80秒
    when 200
      rand(110.00..180.00).round(2) # 200m: 1:50-3:00
    when 400
      rand(240.00..360.00).round(2) # 400m: 4:00-6:00
    when 800
      rand(480.00..720.00).round(2) # 800m: 8:00-12:00
    else
      0
    end

    # 記録を作成
    Record.create!(
      user: user,
      style: style,
      time: time,
      created_at: rand(1..365).days.ago
    )
  end
end

puts "テストデータの作成が完了しました。"
puts "作成されたユーザー数: #{User.count}"
puts "作成された記録数: #{Record.count}"

# ユーザーが既に存在することを前提とします

# 出席イベントの作成
puts "出席イベントを作成中..."

# 過去1ヶ月、今月、来月の日付を生成
last_month_dates = (Date.current.prev_month.beginning_of_month..Date.current.prev_month.end_of_month).to_a
current_month_dates = (Date.current.beginning_of_month..Date.current.end_of_month).to_a
next_month_dates = (Date.current.next_month.beginning_of_month..Date.current.next_month.end_of_month).to_a

# タイトル
titles = ["陸トレ", "水泳練", "MTG", "大会"]

# 3ヶ月分のイベント作成
[last_month_dates, current_month_dates, next_month_dates].each do |dates|
  dates.each do |date|
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
end

# 大会を3つ作成（各月1つずつ、土日に設定）
last_month_weekends = last_month_dates.select { |d| [6, 0].include?(d.wday) }
current_month_weekends = current_month_dates.select { |d| [6, 0].include?(d.wday) }
next_month_weekends = next_month_dates.select { |d| [6, 0].include?(d.wday) }

[last_month_weekends, current_month_weekends, next_month_weekends].each do |weekends|
  date = weekends.sample
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
reasons_other = ["電車遅延", "寝坊", "授業が長引いた", "バスが遅れた", "準備に時間がかかった"]

AttendanceEvent.all.each do |event|
  User.all.each do |user|
    # 50%〜90%の確率で出席データを作成
    next unless rand < rand(0.5..0.9)
    status = [:present, :absent, :other].sample
    note =
      case status
      when :absent
        reasons_absent.sample
      when :other
        reasons_other.sample
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

# 大会関連の目標と反省データを作成
puts "大会関連の目標、反省データを作成中..."

# 大会イベントを取得
competition_events = AttendanceEvent.where(is_competition: true).order(:date)
today = Date.current
next_month_start = Date.current.next_month.beginning_of_month
next_month_end = Date.current.next_month.end_of_month

# プレイヤー全員に対して大会関連データを作成
User.where(user_type: 'player').each do |player|
  competition_events.each do |event|
    # プレイヤーの得意種目をランダムに2つ選択
    target_styles = Style.all.sample(2)
    
    target_styles.each do |style|
      # 来月の大会の場合のみObjectiveとMilestoneを作成
      if event.date.between?(next_month_start, next_month_end)
        # Objective（目標）の作成
        objective = Objective.create!(
          user: player,
          attendance_event: event,
          style: style,
          target_time: generate_random_time(style.name_jp) * 0.95, # 現在の記録より5%速い目標
          quantity_note: "週#{rand(3..6)}回の練習を行う",
          quality_title: ["フォーム改善", "スタミナ強化", "スピード向上", "メンタル強化"].sample,
          quality_note: "#{["キック力の向上", "ターンの改善", "呼吸の安定化", "ペース配分の最適化"].sample}を重点的に行う"
        )

        # Milestone（マイルストーン）の作成 - 2つのみ
        milestone_dates = [
          event.date - 2.months,
          event.date - 1.month
        ]

        milestone_dates.each do |milestone_date|
          milestone = Milestone.create!(
            objective: objective,
            milestone_type: ['quality', 'quantity'].sample,
            limit_date: milestone_date,
            note: "#{milestone_date.strftime('%Y年%m月')}の目標: #{["基礎練習の完了", "フォームの完成", "タイムの達成"].sample}"
          )

          # 過去のマイルストーンの場合、レビューを作成
          if milestone_date < today
            MilestoneReview.create!(
              milestone: milestone,
              achievement_rate: rand(60..100),
              negative_note: ["課題が残る", "まだ改善の余地あり", "もう少し頑張れた"].sample,
              positive_note: ["着実に進歩している", "目標に向かって順調", "良い調子で進んでいる"].sample
            )
          end
        end
      end

      # 全ての大会に対してRaceGoalを作成
      race_goal = RaceGoal.create!(
        user: player,
        attendance_event: event,
        style: style,
        time: generate_random_time(style.name_jp) * 0.95,
        note: "#{["スタートダッシュを決める", "ラストスパートを意識", "安定したペース配分で"].sample}"
      )

      # 過去の大会の場合、レースレビューとフィードバックを作成
      if event.date < today
        race_review = RaceReview.create!(
          race_goal: race_goal,
          style: style,
          time: generate_random_time(style.name_jp),
          note: "#{["良いレース展開だった", "課題が見つかった", "次につながる内容"].sample}"
        )

        # ランダムに2人のコーチを選んでフィードバックを作成
        User.where(user_type: 'coach').sample(2).each do |coach|
          RaceFeedback.create!(
            race_goal: race_goal,
            user: coach,
            note: [
              "スタートのリアクションが良かった",
              "ターンでのスピードロスが気になる",
              "後半の粘りが素晴らしい",
              "呼吸のタイミングを見直そう",
              "フォームが安定していた"
            ].sample
          )
        end
      end
    end
  end
end

puts "大会関連のデータ作成が完了しました"
