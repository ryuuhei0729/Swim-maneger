class Api::V1::Admin::SchedulesController < Api::V1::Admin::BaseController
  include DateParser

  before_action :set_attendance_event, only: [ :show, :update, :destroy ]

  # GET /api/v1/admin/schedules
  def index
    events = AttendanceEvent.order(date: :desc)
    
    # event_typeパラメータによるフィルタリング
    if params[:event_type].present?
      case params[:event_type].downcase
      when 'practice'
        events = events.where(is_competition: false)
      when 'competition'
        events = events.where(is_competition: true)
      else
        return render_error("無効なevent_typeです。'practice'または'competition'を指定してください", status: :bad_request)
      end
    end

    render_success({
      schedules: events.map do |event|
        serialize_schedule(event)
      end
    })
  end

  # GET /api/v1/admin/schedules/:id
  def show
    render_success({
      schedule: serialize_schedule(@attendance_event)
    })
  end

  # POST /api/v1/admin/schedules
  def create
    event = AttendanceEvent.new(schedule_params)

    if event.save
      render_success({
        schedule: serialize_schedule(event)
      }, "スケジュールを作成しました", status: :created)
    else
      render_error("スケジュールの作成に失敗しました", status: :unprocessable_entity, errors: event.errors.full_messages)
    end
  end

  # PATCH /api/v1/admin/schedules/:id
  def update
    if @attendance_event.update(schedule_params)
      render_success({
        schedule: serialize_schedule(@attendance_event)
      }, "スケジュールを更新しました")
    else
      render_error("スケジュールの更新に失敗しました", status: :unprocessable_entity, errors: @attendance_event.errors.full_messages)
    end
  end

  # DELETE /api/v1/admin/schedules/:id
  def destroy
    @attendance_event.destroy
    render_success({}, "スケジュールを削除しました")
  end

  # POST /api/v1/admin/schedules/import/preview
  def import_preview
    unless params[:file].present?
      return render_error("ファイルを選択してください", status: :bad_request)
    end

    begin
      file = params[:file]
      workbook = Roo::Excelx.new(file.tempfile)
      worksheet = workbook.sheet(0)

      # ヘッダー行をスキップ
      rows = worksheet.each_row_streaming(offset: 1)
      preview_data = []

      rows.each_with_index do |row, index|
        next if row.all? { |cell| cell.nil? || cell.value.blank? }

        data = {
          row_number: index + 2, # ヘッダー分を考慮
          title: row[0]&.value,
          date: parse_date(row[1]&.value),
          place: row[2]&.value,
          note: row[3]&.value,
          is_competition: parse_boolean(row[4]&.value),
          is_attendance: parse_boolean(row[5]&.value)
        }

        # バリデーション
        errors = validate_import_data(data)
        data[:errors] = errors
        data[:valid] = errors.empty?

        preview_data << data
      end

      render_success({
        preview_data: preview_data,
        total_rows: preview_data.count,
        valid_rows: preview_data.count { |row| row[:valid] },
        invalid_rows: preview_data.count { |row| !row[:valid] }
      })

    rescue => e
      Rails.logger.error "インポートプレビュー処理中にエラーが発生: #{e.message}"
      render_error("ファイルの処理中にエラーが発生しました", status: :unprocessable_entity)
    end
  end

  # POST /api/v1/admin/schedules/import/execute
  def import_execute
    unless params[:preview_data].present?
      return render_error("インポートデータが見つかりません", status: :bad_request)
    end

    success_count = 0
    error_count = 0
    errors = []

    ActiveRecord::Base.transaction do
      params[:preview_data].each do |data|
        # ActionController::Parametersを安全に処理
        data = data.to_unsafe_h if data.is_a?(ActionController::Parameters)

        # サーバーサイドでデータを正規化・検証
        normalized_data = normalize_import_data(data)
        validation_errors = validate_import_data_server_side(normalized_data)

        if validation_errors.any?
          error_count += 1
          row_number = normalized_data[:row_number] || "不明"
          errors << "行#{row_number}: #{validation_errors.join(', ')}"
          next
        end

        # データの種類に応じてモデルを選択
        event = build_event_from_data(normalized_data)

        if event.save
          success_count += 1
        else
          error_count += 1
          row_number = normalized_data[:row_number] || "不明"
          errors << "行#{row_number}: #{event.errors.full_messages.join(', ')}"
        end
      end

      # エラーがある場合はロールバック
      if error_count > 0
        raise ActiveRecord::Rollback
      end
    end

    if error_count > 0
      render_error("一括インポートに失敗しました", status: :unprocessable_entity, errors: errors)
    else
      render_success({
        imported_count: success_count
      }, "#{success_count}件のスケジュールを一括インポートしました")
    end
  end

  # GET /api/v1/admin/schedules/import/template
  def import_template
    render_success({
      template_url: "/templates/schedule_import_template.xlsx",
      instructions: [
        "1列目: タイトル（必須）",
        "2列目: 日付（YYYY-MM-DD形式、必須）",
        "3列目: 場所",
        "4列目: メモ",
        "5列目: 大会フラグ（TRUE/FALSE）",
        "6列目: 出欠管理フラグ（TRUE/FALSE）"
      ]
    })
  end

  private

  def set_attendance_event
    @attendance_event = AttendanceEvent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("スケジュールが見つかりません", status: :not_found)
  end

  def schedule_params
    permitted_params = params.require(:schedule).permit(:title, :date, :place, :note, :is_competition, :is_attendance, :event_type)

    # event_typeをtypeにマッピング
    if permitted_params[:event_type].present?
      permitted_params[:type] = permitted_params.delete(:event_type)
    end

    permitted_params
  end

  def serialize_schedule(event)
    {
      id: event.id,
      title: event.title,
      date: event.date,
      place: event.place,
      note: event.note,
      event_type: event.type,
      is_competition: event.is_competition,
      is_attendance: event.is_attendance,
      created_at: event.created_at,
      updated_at: event.updated_at
    }
  end



  def parse_boolean(value)
    return false if value.blank?

    case value.to_s.downcase
    when "true", "1", "yes", "y", "はい", "○"
      true
    else
      false
    end
  end

  def validate_import_data(data)
    errors = []

    errors << "タイトルが必須です" if data[:title].blank?
    errors << "日付が必須です" if data[:date].blank?
    errors << "日付の形式が正しくありません" if !data[:date].blank? && parse_date(data[:date]).nil?

    errors
  end

  # サーバーサイドでのインポートデータ正規化
  def normalize_import_data(data)
    normalized = {}

    # row_numberを整数に正規化
    normalized[:row_number] = data[:row_number].to_i if data[:row_number].present?

    # タイトルを文字列に正規化（前後の空白を削除）
    normalized[:title] = data[:title].to_s.strip if data[:title].present?

    # 日付を正規化
    if data[:date].present?
      parsed_date = parse_date(data[:date])
      normalized[:date] = parsed_date if parsed_date
    end

    # 場所とメモを文字列に正規化
    normalized[:place] = data[:place].to_s.strip if data[:place].present?
    normalized[:note] = data[:note].to_s.strip if data[:note].present?

    # ブール値を正規化
    normalized[:is_competition] = ActiveModel::Type::Boolean.new.cast(data[:is_competition])
    normalized[:is_attendance] = ActiveModel::Type::Boolean.new.cast(data[:is_attendance])

    normalized
  end

  # サーバーサイドでのインポートデータ検証
  def validate_import_data_server_side(data)
    errors = []

    # 必須フィールドの検証
    errors << "タイトルが必須です" if data[:title].blank?
    errors << "日付が必須です" if data[:date].blank?

    # 日付の妥当性検証
    if data[:date].present?
      unless data[:date].is_a?(Date)
        errors << "日付の形式が正しくありません"
      end
    end

    # タイトルの長さ検証
    if data[:title].present? && data[:title].length > 255
      errors << "タイトルが長すぎます（255文字以内）"
    end

    # 場所の長さ検証
    if data[:place].present? && data[:place].length > 255
      errors << "場所が長すぎます（255文字以内）"
    end

    # メモの長さ検証
    if data[:note].present? && data[:note].length > 1000
      errors << "メモが長すぎます（1000文字以内）"
    end

    errors
  end

  # 正規化されたデータからイベントオブジェクトを構築
  def build_event_from_data(data)
    if data[:is_competition] && data[:is_attendance]
      # 大会の場合
      Competition.new(
        title: data[:title],
        date: data[:date],
        place: data[:place],
        note: data[:note]
      )
    elsif data[:is_attendance]
      # 練習・出欠管理イベントの場合
      AttendanceEvent.new(
        title: data[:title],
        date: data[:date],
        place: data[:place],
        note: data[:note]
      )
    else
      # 一般イベントの場合
      Event.new(
        title: data[:title],
        date: data[:date],
        place: data[:place],
        note: data[:note]
      )
    end
  end
end
