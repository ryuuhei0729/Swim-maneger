namespace :close_past_events do
  desc "過去のイベントの出欠受付とエントリーを自動的に終了する"
  task close_past_events: :environment do
    puts "過去のイベントの出欠受付とエントリーを終了しています..."
    
    today = Date.current
    total_attendance_count = 0
    competitions_entry_count = 0
    
    # 過去のAttendanceEventを全てclosedに更新
    begin
      past_attendance_events = AttendanceEvent.where("date < ? AND attendance_status != ?", today, AttendanceEvent.attendance_statuses[:closed])
      attendance_events_count = past_attendance_events.count
      past_attendance_events.update_all(attendance_status: AttendanceEvent.attendance_statuses[:closed])
      total_attendance_count += attendance_events_count
      puts "AttendanceEvent更新完了: #{attendance_events_count}件"
    rescue => e
      puts "エラー: AttendanceEventの更新中にエラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
    
    # 過去のCompetitionを全てclosedに更新（出欠受付）
    begin
      past_competitions = Competition.where("date < ? AND attendance_status != ?", today, Competition.attendance_statuses[:closed])
      competitions_count = past_competitions.count
      past_competitions.update_all(attendance_status: Competition.attendance_statuses[:closed])
      total_attendance_count += competitions_count
      puts "Competition出欠受付更新完了: #{competitions_count}件"
    rescue => e
      puts "エラー: Competitionの出欠受付更新中にエラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
    
    # 過去のCompetitionのエントリーを全てclosedに更新
    begin
      past_competitions_entry = Competition.where("date < ? AND entry_status != ?", today, Competition.entry_statuses[:closed])
      competitions_entry_count = past_competitions_entry.count
      past_competitions_entry.update_all(entry_status: Competition.entry_statuses[:closed])
      puts "Competitionエントリー更新完了: #{competitions_entry_count}件"
    rescue => e
      puts "エラー: Competitionのエントリー更新中にエラーが発生しました: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
    
    puts "完了: #{total_attendance_count}件の過去イベントの出欠受付を終了しました"
    puts "完了: #{competitions_entry_count}件の過去大会のエントリーを終了しました"
  end
end 