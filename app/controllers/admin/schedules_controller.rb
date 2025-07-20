class Admin::SchedulesController < Admin::BaseController
  def index
    @events = Event.order(date: :desc).page(params[:page]).per(10)
    @event = AttendanceEvent.new
  end

  def create
    event_type = params[:attendance_event][:event_type]
    
    case event_type
    when "Competition"
      @event = Competition.new(schedule_params)
    when "AttendanceEvent"
      @event = AttendanceEvent.new(schedule_params)
    when "Event", nil
      # 何も選択されていない場合もEventとして保存
      @event = Event.new(schedule_params)
    else
      # 無効な値の場合はEventとして保存
      @event = Event.new(schedule_params)
    end
    
    if @event.save
      redirect_to admin_schedule_path, notice: "スケジュールを登録しました。"
    else
      @events = Event.order(date: :desc).page(params[:page]).per(10)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @event = Event.find(params[:id])
    if @event.update(schedule_params)
      redirect_to admin_schedule_path, notice: "スケジュールを更新しました。"
    else
      @events = Event.order(date: :desc).page(params[:page]).per(10)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to admin_schedule_path, notice: "スケジュールを削除しました。"
  end

  def edit
    @event = Event.find(params[:id])
    respond_to do |format|
      format.json { render json: {
        title: @event.title,
        date: @event.date.strftime("%Y-%m-%d"),
        type: @event.class.name,
        note: @event.note,
        place: @event.place
      }}
    end
  end

  # ======= 一括インポート機能 =======
  def import
    # 一括登録画面を表示
    if params[:clear_preview]
      session.delete(:schedule_import_preview)
      @preview_data = nil
    else
      @preview_data = session[:schedule_import_preview]
    end
  end

  def import_template
    # 手動で作成したテンプレートファイルをダウンロード
    template_path = Rails.root.join('public', 'templates', 'schedule_template_2025.xlsx')
    
    unless File.exist?(template_path)
      redirect_to admin_schedule_import_path, alert: "テンプレートファイルが見つかりません。"
      return
    end
    
    send_file template_path, 
              filename: "schedule_template_#{Date.current.year}.xlsx", 
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  def import_preview
    if params[:csv_file].present?
      require 'rubyXL'
      
      begin
        excel_file = params[:csv_file]
        @preview_data = []
        @errors = []
        
        # ファイルバリデーション: content_typeとファイル拡張子をチェック
        valid_content_types = [
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',  # .xlsx
          'application/vnd.ms-excel',  # .xls
          'application/excel',
          'application/x-excel',
          'application/x-msexcel'
        ]
        
        valid_extensions = ['.xlsx', '.xls']
        file_extension = File.extname(excel_file.original_filename).downcase
        
        # content_typeのバリデーション
        unless valid_content_types.include?(excel_file.content_type)
          @errors << "無効なファイル形式です。Excelファイル（.xlsx または .xls）をアップロードしてください。（検出されたタイプ: #{excel_file.content_type}）"
          render :import
          return
        end
        
        # ファイル拡張子のバリデーション
        unless valid_extensions.include?(file_extension)
          @errors << "無効なファイル拡張子です。.xlsx または .xls ファイルをアップロードしてください。（検出された拡張子: #{file_extension}）"
          render :import
          return
        end
        
        # Excelファイルを読み込み
        workbook = RubyXL::Parser.parse(excel_file.path)
        current_year = Date.current.year
        
        # 各シート（月）を処理
        (1..12).each do |month|
          sheet_name = "#{month}月"
          worksheet = workbook[sheet_name]
          
          next unless worksheet
          
          # シート内の各行を処理（ヘッダー行をスキップ）
          worksheet.each_with_index do |row, row_index|
            next if row_index == 0  # ヘッダー行をスキップ
            next unless row
            
            # セルの値を取得
            day_cell = row[0]
            title_cell = row[2]
            place_cell = row[3]
            note_cell = row[4]
            competition_cell = row[5]
            attendance_cell = row[6]  # G列：出欠フラグ
            
            # 日付とタイトルが空白の場合はスキップ
            next if day_cell.nil? || title_cell.nil? || title_cell.value.blank?
            
            day = day_cell.value
            title = title_cell.value.to_s.strip
            
            # タイトルが空白の場合はスキップ
            next if title.blank?
            
            # 日付の妥当性チェック
            begin
              date = Date.new(current_year, month, day.to_i)
            rescue => e
              @errors << "不正な日付です: #{current_year}/#{month}/#{day} (#{e.message})"
              next
            end
            
            # 場所と備考の取得（nilの場合は空文字列）
            place = place_cell&.value.to_s.strip
            note = note_cell&.value.to_s.strip
            
            # 大会フラグの判定（より厳密に）
            competition_value = competition_cell&.value.to_s.downcase.strip
            is_competition = ["true", "1", "大会", "yes", "○", "o", "〇"].include?(competition_value)
            
            # 出欠フラグの判定
            attendance_value = attendance_cell&.value
            requires_attendance_input = case attendance_value
                                        when true, "true", "TRUE", "1", "○", "o", "〇", "yes", "YES"
                                          true
                                        when false, "false", "FALSE", "0", "×", "x", "no", "NO"
                                          false
                                        else
                                          # 空白やnilの場合はデフォルトでfalse（Eventテーブル）
                                          false
                                        end
            
            # ビジネスロジック: 大会フラグがtrueの場合、出欠管理フラグを強制的にtrueにする
            if is_competition
              requires_attendance = true
            else
              requires_attendance = requires_attendance_input
            end
            
            @preview_data << {
              title: title,
              date: date,
              place: place,
              note: note,
              is_competition: is_competition,
              requires_attendance: requires_attendance
            }
          end
        end
        
        # プレビューデータをセッションに保存
        session[:schedule_import_preview] = @preview_data
        
      rescue => e
        @errors = ["Excelファイルの読み込みに失敗しました: #{e.message}"]
        @preview_data = []
      end
    else
      @errors = ["ファイルが選択されていません"]
      @preview_data = []
    end
    
    render :import
  end

  def import_execute
    preview_data = session[:schedule_import_preview]
    
    if preview_data.blank?
      redirect_to admin_schedule_import_path, alert: "プレビューデータが見つかりません。CSVファイルを再度アップロードしてください。"
      return
    end
    
    success_count = 0
    errors = []
    
    ActiveRecord::Base.transaction do
      preview_data.each_with_index do |data, index|
        requires_attendance = data["requires_attendance"]
        
        if requires_attendance
          # 出欠管理が必要な場合はAttendanceEventテーブル
          event = AttendanceEvent.new(
            title: data["title"],
            date: data["date"],
            place: data["place"],
            note: data["note"],
            is_competition: data["is_competition"]
          )
          table_name = "AttendanceEvent"
        else
          # 出欠管理が不要な場合はEventテーブル
          event = Event.new(
            title: data["title"],
            date: data["date"],
            place: data["place"],
            note: data["note"]
          )
          table_name = "Event"
        end
        
        if event.save
          success_count += 1
        else
          error_msg = "#{data["title"] || '(タイトルなし)'} (#{data["date"]}): #{event.errors.full_messages.join(', ')}"
          errors << error_msg
        end
      end
      
      if errors.any?
        raise ActiveRecord::Rollback
      end
    end
    
    # セッションをクリア
    session.delete(:schedule_import_preview)
    
    if errors.any?
      redirect_to admin_schedule_import_path, alert: "一括登録に失敗しました: #{errors.join('; ')}"
    else
      redirect_to admin_schedule_path, notice: "#{success_count}件のスケジュールを一括登録しました。"
    end
  end

  private

  def schedule_params
    params.require(:attendance_event).permit(:title, :date, :note, :place)
  end
end 