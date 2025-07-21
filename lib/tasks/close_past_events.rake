namespace :close_past_events do
  desc "過去のイベントの出欠受付とエントリーを自動的に終了する"
  task close_past_events: :environment do
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
    puts "完了: #{total_attendance_count}件の過去イベントの出欠受付を終了しました"
    puts "  - AttendanceEvent: #{attendance_events_count}件"
    puts "  - Competition: #{competitions_count}件"
    puts "完了: #{competitions_entry_count}件の過去大会のエントリーを終了しました"
  end
end 