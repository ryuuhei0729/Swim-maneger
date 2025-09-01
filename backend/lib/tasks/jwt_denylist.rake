namespace :jwt_denylist do
  desc "有効期限切れのJWT denylistレコードをクリーンアップ"
  task cleanup: :environment do
    puts "JWT denylistのクリーンアップを開始..."
    
    before_count = JwtDenylist.count
    JwtDenylist.cleanup_expired
    after_count = JwtDenylist.count
    cleaned_count = before_count - after_count
    
    puts "クリーンアップ完了: #{cleaned_count}件のレコードを削除"
    puts "残りレコード数: #{after_count}"
  end

  desc "JWT denylistの統計情報を表示"
  task stats: :environment do
    total_count = JwtDenylist.count
    expired_count = JwtDenylist.expired.count
    valid_count = total_count - expired_count
    
    puts "JWT Denylist 統計情報:"
    puts "総レコード数: #{total_count}"
    puts "有効期限切れ: #{expired_count}"
    puts "有効: #{valid_count}"
    
    if total_count > 0
      oldest_record = JwtDenylist.order(:created_at).first
      newest_record = JwtDenylist.order(:created_at).last
      
      puts "最古のレコード: #{oldest_record.created_at}"
      puts "最新のレコード: #{newest_record.created_at}"
    end
  end
end
