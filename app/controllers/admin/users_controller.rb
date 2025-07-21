class Admin::UsersController < Admin::BaseController
  def index
    # API用（既存のビューファイルはcreateアクションを使用）
    redirect_to admin_create_user_path
  end

  def create
    if request.post?
      @user = User.new(user_params)
      @user_auth = UserAuth.new(user_auth_params)

      User.transaction do
        if @user.save
          @user_auth.user = @user
          if @user_auth.save
            redirect_to admin_path, notice: "ユーザーを作成しました。"
          else
            @user.destroy
            if @user_auth.errors.any?
              @user_auth.errors.messages.each do |attribute, messages|
                messages.each do |message|
                  if message.is_a?(Symbol)
                    translated_message = I18n.t("errors.messages.#{message}", default: I18n.t("activerecord.errors.messages.#{message}", default: message))
                    @user.errors.add(attribute, translated_message)
                  else
                    @user.errors.add(attribute, message)
                  end
                end
              end
            end
            render :create, status: :unprocessable_entity
          end
        else
          render :create, status: :unprocessable_entity
        end
      end
    else
      @user = User.new
      @user_auth = UserAuth.new
    end
  end

  # ======= 一括インポート機能 =======
  def import
    # 一括登録画面を表示
    if params[:clear_preview]
      # 新旧両方の一時ファイルを削除
      temp_file_path_new = Rails.root.join('tmp', "user_import_preview_#{session.id}.enc")
      temp_file_path_old = Rails.root.join('tmp', "user_import_preview_#{session.id}.json")
      File.delete(temp_file_path_new) if File.exist?(temp_file_path_new)
      File.delete(temp_file_path_old) if File.exist?(temp_file_path_old)
      @preview_data = nil
    else
      temp_file_path = Rails.root.join('tmp', "user_import_preview_#{session.id}.enc")
      if File.exist?(temp_file_path)
        begin
          encrypted_data = File.read(temp_file_path)
          decrypted_json = decrypt_preview_data(encrypted_data)
          @preview_data = JSON.parse(decrypted_json)
        rescue => e
          Rails.logger.error "Failed to decrypt preview data: #{e.message}"
          @preview_data = nil
        end
      else
        @preview_data = nil
      end
    end
  end

  def import_template
    # テンプレートファイルをダウンロード
    template_path = Rails.root.join('public', 'templates', 'create_user_template.xlsx')
    
    unless File.exist?(template_path)
      redirect_to admin_users_import_path, alert: "テンプレートファイルが見つかりません。"
      return
    end
    
    send_file template_path, 
              filename: "user_template_#{Date.current.year}.xlsx", 
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
        worksheet = workbook['登録シート'] # 「登録シート」という名前のシートを取得
        
        unless worksheet
          @errors << "「登録シート」という名前のシートが見つかりません。テンプレートファイルを使用してください。"
          @preview_data = []
          render :import
          return
        end
        
        # シート内の各行を処理（ヘッダー行をスキップ）
        worksheet.each_with_index do |row, row_index|
          next if row_index == 0  # ヘッダー行をスキップ
          next unless row
          
          # セルの値を取得
          name_cell = row[0]
          email_cell = row[1] 
          password_cell = row[2]
          user_type_cell = row[3]
          generation_cell = row[4]
          gender_cell = row[5]
          birthday_cell = row[6]
          
          # 名前とメールアドレスが空白の場合はスキップ
          next if name_cell.nil? || email_cell.nil? || name_cell.value.blank? || email_cell.value.blank?
          
          name = name_cell.value.to_s.strip
          email = email_cell.value.to_s.strip
          password = password_cell&.value.to_s.strip || "password"
          user_type = user_type_cell&.value.to_s.strip
          generation = generation_cell&.value
          gender = gender_cell&.value.to_s.strip
          birthday_value = birthday_cell&.value
          
          # 名前とメールアドレスが空白の場合はスキップ
          next if name.blank? || email.blank?
          
          # バリデーション
          user_type_mapping = {
            "選手" => "player",
            "コーチ" => "coach", 
            "顧問・監督" => "director",
            "顧問" => "director",
            "マネージャー" => "manager",
            "player" => "player",
            "coach" => "coach",
            "director" => "director", 
            "manager" => "manager"
          }
          
          mapped_user_type = user_type_mapping[user_type] || user_type
          unless ["player", "coach", "director", "manager"].include?(mapped_user_type)
            @errors << "行#{row_index + 1}: 無効なユーザータイプです: #{user_type}"
            next
          end
          
          gender_mapping = {
            "男性" => "male",
            "女性" => "female", 
            "male" => "male",
            "female" => "female"
          }
          
          mapped_gender = gender_mapping[gender] || gender
          unless ["male", "female"].include?(mapped_gender)
            @errors << "行#{row_index + 1}: 無効な性別です: #{gender}"
            next
          end
          
          # 生年月日の処理
          birthday = nil
          if birthday_value.present?
            begin
              if birthday_value.is_a?(Date)
                birthday = birthday_value
              elsif birthday_value.is_a?(DateTime)
                birthday = birthday_value.to_date
              elsif birthday_value.is_a?(Numeric)
                # Excelの日付シリアル値の場合
                birthday = Date.new(1900, 1, 1) + (birthday_value - 2).days
              else
                birthday = Date.parse(birthday_value.to_s)
              end
            rescue => e
              @errors << "行#{row_index + 1}: 無効な生年月日です: #{birthday_value} (#{e.message})"
              next
            end
          end
          
          # 期数の処理
          generation_num = generation.to_i if generation.present?
          if generation_num.nil? || generation_num < 0
            @errors << "行#{row_index + 1}: 有効な期数を入力してください: #{generation}"
            next
          end
          
          @preview_data << {
            name: name,
            email: email,
            password: password,
            user_type: mapped_user_type,
            generation: generation_num,
            gender: mapped_gender,
            birthday: birthday
          }
        end
        
        # プレビューデータを暗号化して一時ファイルに保存
        temp_file_path = Rails.root.join('tmp', "user_import_preview_#{session.id}.enc")
        encrypted_data = encrypt_preview_data(@preview_data.to_json)
        File.write(temp_file_path, encrypted_data)
        
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
    temp_file_path = Rails.root.join('tmp', "user_import_preview_#{session.id}.enc")
    
    if File.exist?(temp_file_path)
      begin
        encrypted_data = File.read(temp_file_path)
        decrypted_json = decrypt_preview_data(encrypted_data)
        preview_data = JSON.parse(decrypted_json)
      rescue => e
        Rails.logger.error "Failed to decrypt preview data: #{e.message}"
        preview_data = nil
      end
    else
      preview_data = nil
    end
    
    if preview_data.blank?
      redirect_to admin_users_import_path, alert: "プレビューデータが見つかりません。Excelファイルを再度アップロードしてください。"
      return
    end
    
    success_count = 0
    errors = []
    
    ActiveRecord::Base.transaction do
      preview_data.each_with_index do |data, index|
        user = User.new(
          name: data["name"],
          user_type: data["user_type"],
          generation: data["generation"], 
          gender: data["gender"],
          birthday: data["birthday"]
        )
        
        user_auth = UserAuth.new(
          email: data["email"],
          password: data["password"],
          password_confirmation: data["password"]
        )
        
        if user.save
          user_auth.user = user
          if user_auth.save
            success_count += 1
          else
            user.destroy
            error_msg = "#{data["name"]} (#{data["email"]}): #{user_auth.errors.full_messages.join(', ')}"
            errors << error_msg
          end
        else
          error_msg = "#{data["name"]} (#{data["email"]}): #{user.errors.full_messages.join(', ')}"
          errors << error_msg
        end
      end
      
      if errors.any?
        raise ActiveRecord::Rollback
      end
    end
    
    # 一時ファイルをクリア（新旧両方）
    temp_file_path_new = Rails.root.join('tmp', "user_import_preview_#{session.id}.enc")
    temp_file_path_old = Rails.root.join('tmp', "user_import_preview_#{session.id}.json")
    File.delete(temp_file_path_new) if File.exist?(temp_file_path_new)
    File.delete(temp_file_path_old) if File.exist?(temp_file_path_old)
    
    if errors.any?
      redirect_to admin_users_import_path, alert: "一括登録に失敗しました: #{errors.join('; ')}"
    else
      redirect_to admin_create_user_path, notice: "#{success_count}人のユーザーを一括登録しました。"
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday)
  end

  def user_auth_params
    if params[:user_auth].present?
      params.require(:user_auth).permit(:email, :password, :password_confirmation)
    else
      # フォームからuser_authパラメータが送信されていない場合、userパラメータから取得
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
  end
end 