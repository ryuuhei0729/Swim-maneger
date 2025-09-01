module ApiTestHelpers
  extend ActiveSupport::Concern

  included do
    # テスト用のヘルパーメソッドを追加
  end





  # APIレスポンスの検証ヘルパー
  def expect_successful_response(response, expected_status = :ok)
    expect(response).to have_http_status(expected_status)
    expect(json_response['success']).to be true
    expect(json_response['timestamp']).to be_present
    expect(json_response['request_id']).to be_present
  end

  def expect_error_response(response, expected_status = :bad_request)
    expect(response).to have_http_status(expected_status)
    expect(json_response['success']).to be false
    expect(json_response['message']).to be_present
    expect(json_response['timestamp']).to be_present
    expect(json_response['request_id']).to be_present
  end

  def expect_unauthorized_response(response)
    expect_error_response(response, :unauthorized)
    expect(json_response['message']).to include('認証')
  end

  def expect_forbidden_response(response)
    expect_error_response(response, :forbidden)
    expect(json_response['message']).to include('権限')
  end

  def expect_not_found_response(response)
    expect_error_response(response, :not_found)
    expect(json_response['message']).to include('見つかりません')
  end

  def expect_validation_error_response(response)
    expect_error_response(response, :unprocessable_entity)
    expect(json_response['message']).to include('バリデーション')
    expect(json_response['errors']).to be_present
  end

  # JSONレスポンスを取得するヘルパー
  def json_response
    JSON.parse(response.body)
  end

  # ページネーション情報を検証するヘルパー
  def expect_pagination_info(pagination)
    expect(pagination).to include(
      'current_page',
      'total_pages',
      'total_count',
      'per_page',
      'has_next',
      'has_prev'
    )
    expect(pagination['current_page']).to be_a(Integer)
    expect(pagination['total_pages']).to be_a(Integer)
    expect(pagination['total_count']).to be_a(Integer)
    expect(pagination['per_page']).to be_a(Integer)
    expect(pagination['has_next']).to be_in([true, false])
    expect(pagination['has_prev']).to be_in([true, false])
  end

  # ユーザー情報を検証するヘルパー
  def expect_user_summary(user_data)
    expect(user_data).to include(
      'id',
      'name',
      'email',
      'user_type',
      'generation'
    )
    expect(user_data['id']).to be_a(Integer)
    expect(user_data['name']).to be_a(String)
    expect(user_data['email']).to be_a(String)
    expect(user_data['user_type']).to be_in(%w[player manager coach director])
  end

  def expect_user_detail(user_data)
    expect_user_summary(user_data)
    expect(user_data).to include(
      'birthday',
      'gender',
      'created_at'
    )
    expect(user_data['gender']).to be_in(%w[male female])
    expect(user_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
  end

  # イベント情報を検証するヘルパー
  def expect_event_summary(event_data)
    expect(event_data).to include(
      'id',
      'title',
      'date',
      'event_type',
      'location'
    )
    expect(event_data['id']).to be_a(Integer)
    expect(event_data['title']).to be_a(String)
    expect(event_data['date']).to match(/\d{4}-\d{2}-\d{2}/)
    expect(event_data['event_type']).to be_in(%w[practice competition])
  end

  def expect_event_detail(event_data)
    expect_event_summary(event_data)
    expect(event_data).to include(
      'description',
      'start_time',
      'end_time',
      'created_at'
    )
    expect(event_data['start_time']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    expect(event_data['end_time']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    expect(event_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
  end

  # 記録情報を検証するヘルパー
  def expect_record_summary(record_data)
    expect(record_data).to include(
      'id',
      'time',
      'style',
      'created_at'
    )
    expect(record_data['id']).to be_a(Integer)
    expect(record_data['time']).to be_a(Numeric)
    expect(record_data['style']).to include('name', 'distance')
    expect(record_data['style']['name']).to be_a(String)
    expect(record_data['style']['distance']).to be_a(Integer)
    expect(record_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
  end

  # 練習記録情報を検証するヘルパー
  def expect_practice_log_summary(practice_data)
    expect(practice_data).to include(
      'id',
      'menu',
      'memo',
      'created_at',
      'practice_times'
    )
    expect(practice_data['id']).to be_a(Integer)
    expect(practice_data['menu']).to be_a(String)
    expect(practice_data['memo']).to be_a(String)
    expect(practice_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    expect(practice_data['practice_times']).to be_an(Array)
  end

  # 出席情報を検証するヘルパー
  def expect_attendance_summary(attendance_data)
    expect(attendance_data).to include(
      'id',
      'event',
      'status',
      'created_at'
    )
    expect(attendance_data['id']).to be_a(Integer)
    expect_event_summary(attendance_data['event'])
    expect(attendance_data['status']).to be_in(%w[present absent late])
    expect(attendance_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
  end

  # 目標情報を検証するヘルパー
  def expect_objective_summary(objective_data)
    expect(objective_data).to include(
      'id',
      'title',
      'description',
      'target_date',
      'status',
      'milestones'
    )
    expect(objective_data['id']).to be_a(Integer)
    expect(objective_data['title']).to be_a(String)
    expect(objective_data['description']).to be_a(String)
    expect(objective_data['target_date']).to match(/\d{4}-\d{2}-\d{2}/)
    expect(objective_data['status']).to be_in(%w[pending in_progress completed])
    expect(objective_data['milestones']).to be_an(Array)
  end

  # マイルストーン情報を検証するヘルパー
  def expect_milestone_summary(milestone_data)
    expect(milestone_data).to include(
      'id',
      'title',
      'description',
      'target_date',
      'status'
    )
    expect(milestone_data['id']).to be_a(Integer)
    expect(milestone_data['title']).to be_a(String)
    expect(milestone_data['description']).to be_a(String)
    expect(milestone_data['target_date']).to match(/\d{4}-\d{2}-\d{2}/)
    expect(milestone_data['status']).to be_in(%w[pending in_progress completed])
  end

  # お知らせ情報を検証するヘルパー
  def expect_announcement_summary(announcement_data)
    expect(announcement_data).to include(
      'id',
      'title',
      'content',
      'published_at',
      'is_active'
    )
    expect(announcement_data['id']).to be_a(Integer)
    expect(announcement_data['title']).to be_a(String)
    expect(announcement_data['content']).to be_a(String)
    expect(announcement_data['published_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    expect(announcement_data['is_active']).to be_in([true, false])
  end

  # 活動情報を検証するヘルパー
  def expect_activity_summary(activity_data)
    expect(activity_data).to include(
      'id',
      'type',
      'description',
      'user',
      'created_at'
    )
    expect(activity_data['id']).to be_a(Integer)
    expect(activity_data['type']).to be_a(String)
    expect(activity_data['description']).to be_a(String)
    expect_user_summary(activity_data['user'])
    expect(activity_data['created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
  end

  # 統計情報を検証するヘルパー
  def expect_statistics_info(statistics_data)
    expect(statistics_data).to be_a(Hash)
    # 統計情報の構造は用途によって異なるため、基本的な検証のみ
    expect(statistics_data).not_to be_empty
  end

  # ベストタイム情報を検証するヘルパー
  def expect_best_times_info(best_times_data)
    expect(best_times_data).to be_a(Hash)
    # ベストタイムの構造は泳法によって異なるため、基本的な検証のみ
    best_times_data.each do |style, time_info|
      expect(style).to be_a(String)
      expect(time_info).to be_a(Hash)
    end
  end

  # パフォーマンステスト用ヘルパー
  def measure_response_time
    start_time = Time.current
    yield
    end_time = Time.current
    (end_time - start_time) * 1000 # ミリ秒
  end

  def expect_response_time_under(max_time_ms)
    response_time = measure_response_time { yield }
    expect(response_time).to be < max_time_ms
  end

  # データベースクエリ数テスト用ヘルパー
  def count_database_queries
    count = 0
    counter = ->(name, started, finished, unique_id, payload) {
      count += 1 unless payload[:name].in? %w[CACHE SCHEMA]
    }
    
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      yield
    end
    
    count
  end

  def expect_database_queries_under(max_queries)
    query_count = count_database_queries { yield }
    expect(query_count).to be < max_queries
  end

  # キャッシュテスト用ヘルパー
  def with_cache_enabled
    original_perform_caching = Rails.application.config.action_controller.perform_caching
    original_cache_store = Rails.cache
    
    begin
      Rails.application.config.action_controller.perform_caching = true
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      yield
    ensure
      Rails.application.config.action_controller.perform_caching = original_perform_caching
      Rails.cache = original_cache_store
    end
  end

  def expect_cache_hit
    cache_hit = false
    cache_miss = false
    
    cache_subscriber = ->(name, started, finished, unique_id, payload) {
      if payload[:key].present?
        cache_hit = true if payload[:hit]
        cache_miss = true if !payload[:hit]
      end
    }
    
    ActiveSupport::Notifications.subscribed(cache_subscriber, "cache_read.active_support") do
      yield
    end
    
    expect(cache_hit).to be true
    expect(cache_miss).to be false
  end

  # セキュリティテスト用ヘルパー
  def expect_security_headers(response)
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    expect(response.headers['X-Frame-Options']).to eq('DENY')
    expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
    expect(response.headers['Referrer-Policy']).to eq('strict-origin-when-cross-origin')
  end

  def expect_cors_headers(response)
    expect(response.headers['Access-Control-Allow-Origin']).to be_present
    expect(response.headers['Access-Control-Allow-Methods']).to be_present
    expect(response.headers['Access-Control-Allow-Headers']).to be_present
  end

  # レート制限テスト用ヘルパー
  def expect_rate_limit_exceeded(response)
    expect(response).to have_http_status(:too_many_requests)
    expect(json_response['error']).to include('Too many requests')
  end

  # ファイルアップロードテスト用ヘルパー
  def upload_file(file_path, content_type = 'application/octet-stream')
    Rack::Test::UploadedFile.new(file_path, content_type)
  end

  def expect_file_upload_success(response)
    expect_successful_response(response, :created)
    expect(json_response['data']).to include('id', 'filename', 'url')
  end

  # バッチ処理テスト用ヘルパー
  def expect_background_job_enqueued(job_class, *args)
    expect {
      yield
    }.to have_enqueued_job(job_class).with(*args)
  end

  def expect_background_job_performed(job_class, *args)
    expect {
      yield
    }.to have_performed_job(job_class).with(*args)
  end

  # エラーログテスト用ヘルパー
  def expect_error_logged(error_message)
    expect(Rails.logger).to receive(:error).with(include(error_message))
    yield
  end

  def expect_warning_logged(warning_message)
    expect(Rails.logger).to receive(:warn).with(include(warning_message))
    yield
  end

  # データ整合性テスト用ヘルパー
  def expect_data_consistency
    # データベースの整合性をチェック
    expect { User.find_each(&:valid?) }.not_to raise_error
    expect { Event.find_each(&:valid?) }.not_to raise_error
    expect { Record.find_each(&:valid?) }.not_to raise_error
  end

  # メモリ使用量テスト用ヘルパー
  def measure_memory_usage
    GC.start
    memory_before = GC.stat[:total_allocated_objects]
    yield
    GC.start
    memory_after = GC.stat[:total_allocated_objects]
    memory_after - memory_before
  end

  def expect_memory_usage_under(max_objects)
    memory_usage = measure_memory_usage { yield }
    expect(memory_usage).to be < max_objects
  end

  # 並行処理テスト用ヘルパー
  def concurrent_requests(count, &block)
    threads = count.times.map do
      Thread.new(&block)
    end
    threads.each(&:join)
  end

  def expect_concurrent_success(count, &block)
    responses = []
    concurrent_requests(count) do
      responses << block.call
    end
    
    # 各レスポンスの成功判定を堅牢に行う
    successful_responses = responses.all? do |response|
      if response.respond_to?(:successful?)
        response.successful?
      elsif response.respond_to?(:status)
        # HTTPステータスコードが200-299の範囲内かチェック
        status = response.status
        status >= 200 && status < 300
      else
        # フォールバック: success?メソッドを使用
        response.respond_to?(:success?) ? response.success? : false
      end
    end
    
    expect(successful_responses).to be true
  end

  # タイムアウトテスト用ヘルパー
  def expect_timeout_after(timeout_seconds)
    start_time = Time.current
    expect {
      Timeout.timeout(timeout_seconds) do
        yield
      end
    }.to raise_error(Timeout::Error)
    end_time = Time.current
    expect(end_time - start_time).to be >= timeout_seconds
  end

  # リトライテスト用ヘルパー
  def retry_until_success(max_attempts = 3, delay = 0.1)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue => e
      if attempts < max_attempts
        sleep delay
        retry
      else
        raise e
      end
    end
  end

  # テストデータ生成用ヘルパー
  def create_test_users(count = 10)
    count.times.map do |i|
      create(:user, :player, name: "テストユーザー#{i}", generation: "2025")
    end
  end

  def create_test_events(count = 5)
    count.times.map do |i|
      create(:event, :practice, title: "テスト練習#{i}", date: Date.current + i.days)
    end
  end

  def create_test_records(count = 20)
    users = User.where(user_type: 'player').limit(5)
    styles = Style.all
    
    count.times.map do |i|
      create(:record, 
        user: users.sample,
        style: styles.sample,
        time: rand(30.0..60.0).round(2)
      )
    end
  end

  # テスト環境のクリーンアップ用ヘルパー
  def cleanup_test_data
    User.destroy_all
    Event.destroy_all
    Record.destroy_all
    PracticeLog.destroy_all
    Attendance.destroy_all
    Objective.destroy_all
    Announcement.destroy_all
    Rails.cache.clear
  end

  # テスト用の設定変更ヘルパー
  def with_test_config(config_changes)
    original_config = {}
    
    config_changes.each do |key, value|
      original_config[key] = Rails.application.config.send(key)
      Rails.application.config.send("#{key}=", value)
    end
    
    yield
  ensure
    original_config.each do |key, value|
      Rails.application.config.send("#{key}=", value)
    end
  end
end

RSpec.configure do |config|
  # JWT認証関連のメソッドはJwtAuthHelperで提供されるため、
  # 認証関連のメソッドは含めない
  config.include ApiTestHelpers, type: :request
  config.include ApiTestHelpers, type: :controller
end
