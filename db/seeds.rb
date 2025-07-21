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

# ユーザータイプとジェンダーの定義（enum対応）
USER_TYPES = [ :director, :coach, :player, :manager ]
GENDERS = [ :male, :female, :other ]

# データベースをクリア
puts "データベースをクリアしています..."
PracticeTime.destroy_all rescue nil
PracticeLog.destroy_all rescue nil
RaceFeedback.destroy_all rescue nil
RaceReview.destroy_all rescue nil
RaceGoal.destroy_all rescue nil
MilestoneReview.destroy_all rescue nil
Milestone.destroy_all rescue nil
Objective.destroy_all rescue nil
Attendance.destroy_all rescue nil
Record.destroy_all rescue nil
Entry.destroy_all rescue nil
Competition.destroy_all rescue nil
AttendanceEvent.destroy_all rescue nil
Event.destroy_all rescue nil
UserAuth.destroy_all rescue nil
User.destroy_all rescue nil
Style.destroy_all rescue nil

# 種目の作成
puts "種目を作成中..."
styles = [
  { name_jp: "50m自由形", name: "50Fr", style: 0, distance: 50 },
  { name_jp: "100m自由形", name: "100Fr", style: 0, distance: 100 },
  { name_jp: "200m自由形", name: "200Fr", style: 0, distance: 200 },
  { name_jp: "400m自由形", name: "400Fr", style: 0, distance: 400 },
  { name_jp: "800m自由形", name: "800Fr", style: 0, distance: 800 },
  { name_jp: "50m平泳ぎ", name: "50Br", style: 1, distance: 50 },
  { name_jp: "100m平泳ぎ", name: "100Br", style: 1, distance: 100 },
  { name_jp: "200m平泳ぎ", name: "200Br", style: 1, distance: 200 },
  { name_jp: "50m背泳ぎ", name: "50Ba", style: 2, distance: 50 },
  { name_jp: "100m背泳ぎ", name: "100Ba", style: 2, distance: 100 },
  { name_jp: "200m背泳ぎ", name: "200Ba", style: 2, distance: 200 },
  { name_jp: "50mバタフライ", name: "50Fly", style: 3, distance: 50 },
  { name_jp: "100mバタフライ", name: "100Fly", style: 3, distance: 100 },
  { name_jp: "200mバタフライ", name: "200Fly", style: 3, distance: 200 },
  { name_jp: "100m個人メドレー", name: "100IM", style: 4, distance: 100 },
  { name_jp: "200m個人メドレー", name: "200IM", style: 4, distance: 200 },
  { name_jp: "400m個人メドレー", name: "400IM", style: 4, distance: 400 }
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
    user_type: :director,
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
    user_type: :coach,
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
    user_type: :player,
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

# イベントの作成（学校行事）
puts "学校行事を作成中..."

# 2ヶ月に1回、月末にテスト期間がある（4日間、平日）
current_year = Date.current.year
(1..12).each do |month|
  # 2ヶ月ごと（奇数月）にテスト期間を設定
  next if month % 2 == 0

  # 月末の平日を4日間取得
  end_of_month = Date.new(current_year, month, 1).end_of_month
  weekdays = []

  # 月末から遡って平日を4日間取得
  (0..30).each do |day_offset|
    date = end_of_month - day_offset.days
    if date.month == month && [ 1, 2, 3, 4, 5 ].include?(date.wday) # 月〜金
      weekdays << date
      break if weekdays.length == 4
    end
  end

  # テスト期間のイベントを作成
  weekdays.reverse.each_with_index do |date, index|
    Event.create!(
      title: "テスト期間",
      date: date,
      place: "学校",
      note: "テスト期間#{index + 1}日目。学業に集中してください。"
    )
  end
end

# 1年〜6年の修学旅行がバラバラのタイミングで2日間ある
grades = [ 1, 2, 3, 4, 5, 6 ]
grade_events = {}

grades.each do |grade|
  # 各学年でランダムな月を選択（4月〜11月の間）
  month = rand(4..11)

  # その月の平日を2日間ランダムに選択
  month_start = Date.new(current_year, month, 1)
  month_end = month_start.end_of_month

  weekdays_in_month = []
  (month_start..month_end).each do |date|
    if [ 1, 2, 3, 4, 5 ].include?(date.wday) # 月〜金
      weekdays_in_month << date
    end
  end

  # 2日間をランダムに選択（連続する日付）
  if weekdays_in_month.length >= 2
    start_index = rand(0..weekdays_in_month.length - 2)
    travel_dates = weekdays_in_month[start_index, 2]

    travel_dates.each_with_index do |date, index|
      Event.create!(
        title: "#{grade}年生修学旅行",
        date: date,
        place: "修学旅行先",
        note: "#{grade}年生の修学旅行#{index + 1}日目。楽しい思い出を作ってください。"
      )
    end
  end
end

puts "学校行事の作成が完了しました"
puts "作成された学校行事数: #{Event.count}"

# 練習・ミーティングイベントの作成
puts "練習・ミーティングイベントを作成中..."

# 過去1ヶ月、今月、来月の日付を生成
last_month_dates = (Date.current.prev_month.beginning_of_month..Date.current.prev_month.end_of_month).to_a
current_month_dates = (Date.current.beginning_of_month..Date.current.end_of_month).to_a
next_month_dates = (Date.current.next_month.beginning_of_month..Date.current.next_month.end_of_month).to_a

# 3ヶ月分のイベント作成
[ last_month_dates, current_month_dates, next_month_dates ].each do |dates|
  dates.each do |date|
    case date.wday
    when 1 # 月曜日
      if rand < 0.8 # 80%の確率で
        AttendanceEvent.create!(
          title: "陸トレ",
          date: date,
          place: '小石川5階',
          note: "陸上の練習です。基礎体力向上を目指します。"
        )
      end
    when 2 # 火曜日
      if rand < 0.9 # 90%の確率で
        AttendanceEvent.create!(
          title: "水泳練",
          date: date,
          place: 'コズミック',
          note: "水泳の練習です。フォーム改善に重点を置きます。"
        )
      end
    when 3 # 水曜日
      if rand < 0.7 # 70%の確率で
        AttendanceEvent.create!(
          title: "全体MTG",
          date: date,
          place: 'オンライン',
          note: "今週の予定と目標の確認を行います。"
        )
      end
    when 4 # 木曜日
      if rand < 0.85 # 85%の確率で
        AttendanceEvent.create!(
          title: "水泳練",
          date: date,
          place: 'コズミック',
          note: "水泳の練習です。スピード練習を行います。"
        )
      end
    when 5 # 金曜日
      if rand < 0.75 # 75%の確率で
        AttendanceEvent.create!(
          title: "陸トレ",
          date: date,
          place: '小石川5階',
          note: "陸上の練習です。筋力トレーニングを行います。"
        )
      end
    when 6 # 土曜日
      if rand < 0.6 # 60%の確率で
        AttendanceEvent.create!(
          title: [ "水泳練", "合同練習" ].sample,
          date: date,
          place: 'Bumb',
          note: "週末練習です。実践的な練習を行います。"
        )
      end
    end
  end
end

# 大会を3つ作成（各月1つずつ、土日に設定）
last_month_weekends = last_month_dates.select { |d| [ 6, 0 ].include?(d.wday) }
current_month_weekends = current_month_dates.select { |d| [ 6, 0 ].include?(d.wday) }
next_month_weekends = next_month_dates.select { |d| [ 6, 0 ].include?(d.wday) }

[ last_month_weekends, current_month_weekends, next_month_weekends ].each do |weekends|
  date = weekends.sample
  Competition.create!(
    title: "大会",
    date: date,
    place: 'アクアティクスセンター',
    note: "大会です。全員参加必須です。応援も含めてチーム一丸となって頑張りましょう。"
  )
end

puts "練習・ミーティングイベントの作成が完了しました"
puts "作成された練習・ミーティング数: #{AttendanceEvent.count}"
puts "作成された大会数: #{Competition.count}"

# 記録の作成
puts "Creating records..."

# 過去の大会イベントを取得
competition_events = Competition.where("date < ?", Date.current)

# 大会イベントが存在しない場合、ダミーの大会イベントを作成
if competition_events.empty?
  puts "大会イベントが存在しないため、ダミーの大会イベントを作成します..."
  3.times do |i|
    Competition.create!(
      title: "第#{i + 1}回大会",
      date: rand(30..365).days.ago,
      place: 'アクアティクスセンター',
      note: "大会です。全員参加必須です。"
    )
  end
  competition_events = Competition.where("date < ?", Date.current)
end

# プレイヤー全員に対して記録を作成
User.where(user_type: :player).each do |user|
  # 各大会に対して最大2種目まで出場
  competition_events.each do |competition_event|
    # この大会に参加するかどうかを80%の確率で決定
    next unless rand < 0.8
    
    # この大会で出場する種目数を1〜2種目で決定
    event_count = rand(1..2)
    
    # ランダムに種目を選択
    selected_styles = Style.all.sample(event_count)
    
    selected_styles.each do |style|
      time = case style.distance
      when 50
        rand(22.00..35.00).round(2)  # 50m: 22-35秒
      when 100
        rand(50.00..80.00).round(2)  # 100m: 50-80秒
      when 200
        rand(110.00..180.00).round(2) # 200m: 1:50-3:00
      when 400
        rand(240.00..360.00).round(2)
      when 800
        rand(480.00..720.00).round(2)
      else
        0
      end

      # 記録を作成（大会イベントと関連付け）
      Record.create!(
        user: user,
        style: style,
        time: time,
        attendance_event: competition_event,
        created_at: competition_event.date + rand(0..5).hours
      )
    end
  end
end

# 記録がない種目に対してダミーの記録を作成
puts "記録がない種目に対してダミーの記録を作成中..."
User.where(user_type: :player).each do |user|
  # ユーザーがすでに記録を持っている種目IDのリスト
  recorded_style_ids = user.records.pluck(:style_id)
  # 記録がない種目IDのリスト
  unrecorded_styles = Style.where.not(id: recorded_style_ids)

  # 未記録の種目が多い場合は、一部の種目のみに記録を作成
  styles_to_create = unrecorded_styles.sample([unrecorded_styles.count, 5].min)
  
  styles_to_create.each do |style|
    # ランダムに大会イベントを選択
    competition_event = competition_events.sample
    
    # その大会でのその選手の種目数を確認
    existing_events_count = user.records.where(attendance_event: competition_event).count
    
    # その大会で既に2種目以上出場している場合は別の大会を選択
    if existing_events_count >= 2
      # 2種目未満の大会を探す
      available_events = competition_events.select do |event|
        user.records.where(attendance_event: event).count < 2
      end
      
      if available_events.any?
        competition_event = available_events.sample
      else
        # 全ての大会で2種目以上出場している場合はスキップ
        next
      end
    end
    
    # 種目に応じたランダムなタイムを生成
    time = case style.distance
    when 50
      rand(22.00..35.00).round(2)
    when 100
      rand(50.00..80.00).round(2)
    when 200
      rand(110.00..180.00).round(2)
    when 400
      rand(240.00..360.00).round(2)
    when 800
      rand(480.00..720.00).round(2)
    else
      0
    end

    # 記録を作成（大会イベントと関連付け）
    Record.create!(
      user: user,
      style: style,
      time: time,
      attendance_event: competition_event,
      created_at: competition_event.date + rand(0..5).hours
    )
  end
end

puts "全記録の作成が完了しました。"
puts "作成されたユーザー数: #{User.count}"
puts "作成された記録数: #{Record.count}"

# 出席データの作成
puts "出席データを作成中..."

reasons_absent = [ "体調不良", "家庭の事情", "学業の都合", "用事があるため", "怪我のため" ]
reasons_other = [ "電車遅延", "寝坊", "授業が長引いた", "バスが遅れた", "準備に時間がかかった" ]

# 練習・ミーティングイベントの出席データ
AttendanceEvent.all.each do |event|
  User.all.each do |user|
    # 50%〜90%の確率で出席データを作成
    next unless rand < rand(0.5..0.9)
    status = [0, 1, 2].sample
    note =
      case status
      when 1
        reasons_absent.sample
      when 2
        reasons_other.sample
      else
        nil
      end

    # 既存の出席データがない場合のみ作成
    unless Attendance.exists?(user: user, attendance_event: event)
      Attendance.create!(
        user: user,
        attendance_event: event,
        status: status,
        note: note
      )
    end
  end
end

# 大会の出席データ
Competition.all.each do |competition|
  User.all.each do |user|
    # 大会は90%〜100%の確率で出席データを作成
    next unless rand < rand(0.9..1.0)
    status = [0, 1, 2].sample
    note =
      case status
      when 1
        reasons_absent.sample
      when 2
        reasons_other.sample
      else
        nil
      end

    # 既存の出席データがない場合のみ作成
    unless Attendance.exists?(user: user, attendance_event: competition)
      Attendance.create!(
        user: user,
        attendance_event: competition,
        status: status,
        note: note
      )
    end
  end
end

puts "出席データの作成が完了しました"

# 大会関連の目標と反省データを作成
puts "大会関連の目標、反省データを作成中..."

# 大会イベントを取得
competition_events = Competition.order(:date)
today = Date.current
next_month_start = Date.current.next_month.beginning_of_month
next_month_end = Date.current.next_month.end_of_month

# プレイヤー全員に対して大会関連データを作成
User.where(user_type: :player).each do |player|
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
          quality_title: [ "フォーム改善", "スタミナ強化", "スピード向上", "メンタル強化" ].sample,
          quality_note: "#{[ "キック力の向上", "ターンの改善", "呼吸の安定化", "ペース配分の最適化" ].sample}を重点的に行う"
        )

        # Milestone（マイルストーン）の作成 - 2つのみ
        milestone_dates = [
          event.date - 2.months,
          event.date - 1.month
        ]

        milestone_dates.each do |milestone_date|
          milestone = Milestone.create!(
            objective: objective,
            milestone_type: [ 'quality', 'quantity' ].sample,
            limit_date: milestone_date,
            note: "#{milestone_date.strftime('%Y年%m月')}の目標: #{[ "基礎練習の完了", "フォームの完成", "タイムの達成" ].sample}"
          )

          # 過去のマイルストーンの場合、レビューを作成
          if milestone_date < today
            MilestoneReview.create!(
              milestone: milestone,
              achievement_rate: rand(60..100),
              negative_note: [ "課題が残る", "まだ改善の余地あり", "もう少し頑張れた" ].sample,
              positive_note: [ "着実に進歩している", "目標に向かって順調", "良い調子で進んでいる" ].sample
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
        note: "#{[ "スタートダッシュを決める", "ラストスパートを意識", "安定したペース配分で" ].sample}"
      )

      # 過去の大会の場合、レースレビューとフィードバックを作成
      if event.date < today
        race_review = RaceReview.create!(
          race_goal: race_goal,
          style: style,
          time: generate_random_time(style.name_jp),
          note: "#{[ "良いレース展開だった", "課題が見つかった", "次につながる内容" ].sample}"
        )

        # ランダムに2人のコーチを選んでフィードバックを作成
        User.where(user_type: :coach).sample(2).each do |coach|
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

# 練習記録の作成
puts "練習記録を作成中..."

# 水泳練習のイベントを取得
swim_events = AttendanceEvent.where(title: "水泳練").order(:date)

# 各水泳練習イベントに対して練習ログを作成
swim_events.each do |event|
  # 練習ログの作成
  practice_log = PracticeLog.create!(
    attendance_event: event,
    tags: [ "スプリント", "持久力", "フォーム改善" ].sample(rand(1..3)),
    style: [ "Fr", "Br", "Ba", "Fly", "IM", "S1" ].sample,
    rep_count: [ 1, 3, 5 ].sample,
    set_count: [ 1, 2, 3 ].sample,
    distance: [ 50, 100 ].sample,
    circle: [ 60, 70, 80, 90 ].sample,
    note: [ "スプリント練習", "持久力強化", "フォーム改善", "ターン練習" ].sample
  )

  # プレイヤー全員に対して練習タイムを作成
  User.where(user_type: :player).each do |player|
    # セット数と本数の組み合わせで練習タイムを作成
    (1..practice_log.set_count).each do |set_number|
      (1..practice_log.rep_count).each do |rep_number|
        # 種目に応じたランダムなタイムを生成
        time = case practice_log.distance
        when 50
          rand(30.00..45.00).round(2)  # 50m: 30-45秒
        when 100
          rand(65.00..95.00).round(2)  # 100m: 65-95秒
        else
          0
        end

        PracticeTime.create!(
          user: player,
          practice_log: practice_log,
          rep_number: rep_number,
          set_number: set_number,
          time: time
        )
      end
    end
  end
end

puts "練習記録の作成が完了しました"
puts "作成された練習ログ数: #{PracticeLog.count}"
puts "作成された練習タイム数: #{PracticeTime.count}"

# エントリーデータの作成
puts "エントリーデータを作成中..."

# 今後の大会イベントを取得（エントリー期間中またはこれからエントリーが始まる大会）
future_competitions = Competition.where("date >= ?", Date.current)

# プレイヤー全員に対してエントリーデータを作成
User.where(user_type: :player).each do |player|
  future_competitions.each do |competition|
    # この大会にエントリーするかどうかを70%の確率で決定
    next unless rand < 0.7
    
    # この大会でエントリーする種目数を1〜3種目で決定
    entry_count = rand(1..3)
    
    # ランダムに種目を選択（重複しないように）
    selected_styles = Style.all.sample(entry_count)
    
    selected_styles.each do |style|
      # 種目に応じたエントリータイムを生成（記録より少し遅いタイム）
      entry_time = case style.distance
      when 50
        rand(25.00..40.00).round(2)  # 50m: 25-40秒
      when 100
        rand(55.00..90.00).round(2)  # 100m: 55-90秒
      when 200
        rand(120.00..200.00).round(2) # 200m: 2:00-3:20
      when 400
        rand(260.00..400.00).round(2) # 400m: 4:20-6:40
      when 800
        rand(520.00..780.00).round(2) # 800m: 8:40-13:00
      else
        rand(30.00..60.00).round(2)
      end

      # エントリーノートを生成
      entry_notes = [
        "ベストタイムを目指します",
        "安定した泳ぎで完泳を目指します",
        "フォームを意識して泳ぎます",
        "ペース配分を意識します",
        "スタートダッシュを決めます",
        "ラストスパートを意識します",
        "ターンを改善します",
        "呼吸のタイミングを安定させます"
      ]

      # エントリーを作成
      Entry.create!(
        user: player,
        attendance_event: competition,
        style: style,
        entry_time: entry_time,
        note: entry_notes.sample
      )
    end
  end
end

puts "エントリーデータの作成が完了しました"
puts "作成されたエントリー数: #{Entry.count}"

# 過去のイベントの出欠受付とエントリーを自動的に終了
puts "過去のイベントの出欠受付とエントリーを終了しています..."
today = Date.current

# 過去のAttendanceEventを全てclosedに更新
past_attendance_events = AttendanceEvent.where("date < ? AND attendance_status != ?", today, 2)
attendance_events_count = past_attendance_events.count
past_attendance_events.update_all(attendance_status: 2)

# 過去のCompetitionを全てclosedに更新（出欠受付）
past_competitions = Competition.where("date < ? AND attendance_status != ?", today, 2)
competitions_count = past_competitions.count
past_competitions.update_all(attendance_status: 2)

# 過去のCompetitionのエントリーを全てclosedに更新
past_competitions_entry = Competition.where("date < ? AND entry_status != ?", today, 2)
competitions_entry_count = past_competitions_entry.count
past_competitions_entry.update_all(entry_status: 2)

total_attendance_count = attendance_events_count + competitions_count
puts "過去のイベントの出欠受付を終了しました: #{total_attendance_count}件"
puts "  - AttendanceEvent: #{attendance_events_count}件"
puts "  - Competition: #{competitions_count}件"
puts "過去の大会のエントリーを終了しました: #{competitions_entry_count}件"
