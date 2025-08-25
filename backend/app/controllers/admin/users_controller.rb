class Admin::UsersController < Admin::BaseController
  def index
    @users = User.includes(:user_auth).order(:generation, :name)
  end

  def show
    @user = User.includes(:user_auth).find(params[:id])
    
    # JSONリクエストの場合は直接JSONを返す
    if request.format.json?
      user_data = {
        user: {
          id: @user.id,
          name: @user.name,
          user_type: @user.user_type,
          generation: @user.generation,
          gender: @user.gender,
          birthday: @user.birthday&.strftime('%Y-%m-%d')
        },
        user_auth: {
          email: @user.user_auth&.email
        }
      }
      
      render json: user_data
    else
      # HTMLリクエストの場合は通常のビューを表示
      respond_to do |format|
        format.html
      end
    end
  end

  def edit
    @user = User.includes(:user_auth).find(params[:id])
    @user_auth = @user.user_auth
  end

  def update
    @user = User.find(params[:id])
    @user_auth = @user.user_auth

    begin
      User.transaction do
        if @user.update(user_params)
          if @user_auth.update(user_auth_params)
            respond_to do |format|
              format.html { redirect_to admin_users_path, notice: "ユーザー情報を更新しました。" }
              format.json { render json: { success: true, message: "ユーザー情報を更新しました。" } }
            end
          else
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
            
            # エラーメッセージを統一
            custom_errors = standardize_error_messages(@user, @user_auth)
            
            respond_to do |format|
              format.html { render :edit, status: :unprocessable_entity }
              format.json { render json: { errors: custom_errors }, status: :unprocessable_entity }
            end
          end
        else
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: { errors: @user.errors.messages }, status: :unprocessable_entity }
          end
        end
      end
    rescue => e
      Rails.logger.error "User update error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: "更新中にエラーが発生しました: #{e.message}" }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    
    begin
      if @user.destroy
        respond_to do |format|
          format.html { redirect_to admin_users_path, notice: "ユーザーを削除しました。" }
          format.json { render json: { success: true, message: "ユーザーを削除しました。" } }
        end
      else
        respond_to do |format|
          format.html { redirect_to admin_users_path, alert: "ユーザーの削除に失敗しました。" }
          format.json { render json: { success: false, message: "ユーザーの削除に失敗しました。" }, status: :unprocessable_entity }
        end
      end
    rescue => e
      Rails.logger.error "User destroy error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.html { redirect_to admin_users_path, alert: "ユーザーの削除中にエラーが発生しました。" }
        format.json { render json: { success: false, message: "ユーザーの削除中にエラーが発生しました: #{e.message}" }, status: :internal_server_error }
      end
    end
  end

  def create
    if request.post?
      @user = User.new(user_params)
      @user_auth = UserAuth.new(user_auth_params)

      User.transaction do
        if @user.save
          @user_auth.user = @user
          if @user_auth.save
            redirect_to admin_users_path, notice: "ユーザーを作成しました。"
          else
            @user.destroy
            # エラーメッセージを統一
            custom_errors = standardize_error_messages(@user, @user_auth)
            custom_errors.each do |field, messages|
              messages.each do |message|
                @user.errors.add(field, message)
              end
            end
            render :create, status: :unprocessable_entity
          end
        else
          # エラーメッセージを統一
          custom_errors = standardize_error_messages(@user, @user_auth)
          custom_errors.each do |field, messages|
            messages.each do |message|
              @user.errors.add(field, message)
            end
          end
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
      redirect_to admin_users_path, notice: "#{success_count}人のユーザーを一括登録しました。"
    end
  end

  private

  # エラーメッセージを統一するメソッド
  def standardize_error_messages(user, user_auth)
    custom_errors = {}
    
    # Userモデルのエラーを処理
    user.errors.messages.each do |field, messages|
      custom_errors[field] = get_custom_error_message(field, messages)
    end
    
    # UserAuthモデルのエラーを処理
    if user_auth&.errors&.any?
      user_auth.errors.messages.each do |field, messages|
        custom_errors[field] = get_custom_error_message(field, messages)
      end
    end
    
    custom_errors
  end

  # フィールド別のカスタムエラーメッセージを取得
  def get_custom_error_message(field, messages)
    case field.to_s
    when 'password'
      messages.map { |msg| msg.include?('英数字') ? msg : 'パスワードを入力してください' }
    when 'password_confirmation'
      ['パスワード（確認）を入力してください']
    when 'email'
      messages.map { |msg| msg.include?('形式') ? msg : 'メールアドレスを入力してください' }
    when 'name'
      messages.map { |msg| msg.include?('長さ') ? '名前は255文字以下にしてください' : '名前を入力してください' }
    when 'user_type'
      ['ユーザータイプを選択してください']
    when 'generation'
      messages.map { |msg| msg.include?('数値') ? '期数は0-999の整数で入力してください' : '期数を入力してください' }
    when 'gender'
      ['性別を選択してください']
    when 'birthday'
      messages.map { |msg| 
        if msg.include?('未来')
          '生年月日は未来の日付にできません'
        elsif msg.include?('1900年')
          '生年月日は1900年以降の日付にしてください'
        else
          '生年月日を入力してください'
        end
      }
    else
      messages
    end
  end

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday)
  end

  def user_auth_params
    if params[:user_auth].present?
      permitted_params = params.require(:user_auth).permit(:email, :password, :password_confirmation)
      # パスワードが空の場合はパスワード関連のパラメータを除外
      if permitted_params[:password].blank?
        permitted_params.except(:password, :password_confirmation)
      else
        permitted_params
      end
    else
      # フォームからuser_authパラメータが送信されていない場合、userパラメータから取得
      permitted_params = params.require(:user).permit(:email, :password, :password_confirmation)
      # パスワードが空の場合はパスワード関連のパラメータを除外
      if permitted_params[:password].blank?
        permitted_params.except(:password, :password_confirmation)
      else
        permitted_params
      end
    end
  end
end 