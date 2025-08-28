class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  include DateParser
  
  before_action :set_user, only: [:show, :update, :destroy]

  # GET /api/v1/admin/users
  def index
    users = User.includes(:user_auth).order(:generation, :name)
    
    render_success({
      users: users.map { |user| serialize_user(user) },
      total_count: users.count,
      user_types: User.user_types.keys.map { |key| { key: key, label: key.humanize } },
      genders: User.genders.keys.map { |key| { key: key, label: key.humanize } }
    })
  end

  # GET /api/v1/admin/users/:id
  def show
    render_success({
      user: serialize_user_detail(@user)
    })
  end

  # POST /api/v1/admin/users
  def create
    user = User.new(user_params)
    user_auth = UserAuth.new(user_auth_params)

    User.transaction do
      if user.save
        user_auth.user = user
        if user_auth.save
          render_success({
            user: serialize_user(user)
          }, "ユーザーを作成しました", :created)
        else
          user.destroy
          render_error("ユーザー認証情報の作成に失敗しました", status: :unprocessable_entity, errors: user_auth.errors.as_json)
        end
      else
        render_error("ユーザーの作成に失敗しました", status: :unprocessable_entity, errors: user.errors.as_json)
      end
    end
  end

  # PATCH /api/v1/admin/users/:id
  def update
    user_auth = @user.user_auth
    
    User.transaction do
      if @user.update(user_params)
        if user_auth.present? && user_auth_params.present?
          if user_auth.update(user_auth_params)
            render_success({
              user: serialize_user(@user)
            }, "ユーザー情報を更新しました")
          else
            render_error("ユーザー認証情報の更新に失敗しました", status: :unprocessable_entity, errors: user_auth.errors.as_json)
            raise ActiveRecord::Rollback
          end
        else
          render_success({
            user: serialize_user(@user)
          }, "ユーザー情報を更新しました")
        end
      else
        render_error("ユーザー情報の更新に失敗しました", status: :unprocessable_entity, errors: @user.errors.as_json)
      end
    end
  end

  # DELETE /api/v1/admin/users/:id
  def destroy
    # 論理削除の実装（実際の削除は行わない）
    render_success({}, "ユーザー削除機能は現在無効化されています")
  end

  # POST /api/v1/admin/users/import/preview
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
          name: row[0]&.value,
          user_type: row[1]&.value,
          generation: row[2]&.value,
          gender: row[3]&.value,
          birthday: parse_date(row[4]&.value),
          email: row[5]&.value,
          password: row[6]&.value || "temporary_password"
        }
        
        # バリデーション
        errors = validate_import_user_data(data)
        data[:errors] = errors
        data[:valid] = errors.empty?
        
        # パスワードは表示しない
        data.delete(:password)
        data[:has_password] = row[6]&.value.present?
        
        preview_data << data
      end
      
      # 署名付きトークンを生成（有効なデータのみ）
      valid_data = preview_data.select { |row| row[:valid] }
      token = generate_import_token(valid_data)
      
      render_success({
        preview_data: preview_data,
        import_token: token,
        total_rows: preview_data.count,
        valid_rows: preview_data.count { |row| row[:valid] },
        invalid_rows: preview_data.count { |row| !row[:valid] }
      })
      
    rescue => e
      Rails.logger.error "ユーザーインポートプレビュー処理中にエラーが発生: #{e.message}"
      render_error("ファイルの処理中にエラーが発生しました", status: :unprocessable_entity)
    end
  end

  # POST /api/v1/admin/users/import/execute
  def import_execute
    unless params[:import_token].present?
      return render_error("インポートトークンが見つかりません", status: :bad_request)
    end

    # トークンを検証・デコード
    begin
      import_data = verify_import_token(params[:import_token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      return render_error("無効なインポートトークンです", status: :bad_request)
    rescue => e
      Rails.logger.error "インポートトークンの検証中にエラーが発生: #{e.message}"
      return render_error("インポートトークンの検証に失敗しました", status: :bad_request)
    end

    success_count = 0
    error_count = 0
    errors = []

    User.transaction do
      import_data.each do |data|
        # サーバーサイドでバリデーションを再実行
        validation_errors = validate_import_user_data(data)
        if validation_errors.any?
          error_count += 1
          errors << "行#{data[:row_number]}: バリデーションエラー - #{validation_errors.join(', ')}"
          next
        end

        begin
          user = User.new(
            name: data[:name],
            user_type: data[:user_type],
            generation: data[:generation],
            gender: data[:gender],
            birthday: data[:birthday]
          )
          
          user_auth = UserAuth.new(
            email: data[:email],
            password: data[:password] || "temporary_password",
            password_confirmation: data[:password] || "temporary_password"
          )

          if user.save
            user_auth.user = user
            if user_auth.save
              success_count += 1
            else
              error_count += 1
              errors << "行#{data[:row_number]}: 認証情報の作成に失敗 - #{user_auth.errors.full_messages.join(', ')}"
              user.destroy # ロールバック
            end
          else
            error_count += 1
            errors << "行#{data[:row_number]}: ユーザー作成に失敗 - #{user.errors.full_messages.join(', ')}"
          end
        rescue => e
          error_count += 1
          errors << "行#{data[:row_number]}: #{e.message}"
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
      }, "#{success_count}人のユーザーを一括インポートしました")
    end
  end

  # GET /api/v1/admin/users/import/template
  def import_template
    render_success({
      template_url: "/templates/user_import_template.xlsx",
      instructions: [
        "1列目: 名前（必須）",
        "2列目: ユーザータイプ（player/manager/coach/director、必須）",
        "3列目: 世代（数値、必須）",
        "4列目: 性別（male/female、必須）",
        "5列目: 誕生日（YYYY-MM-DD形式）",
        "6列目: メールアドレス（必須）",
        "7列目: パスワード（空欄の場合は「temporary_password」が設定されます）"
      ],
      sample_data: [
        {
          name: "山田太郎",
          user_type: "player",
          generation: 1,
          gender: "male",
          birthday: "2000-01-01",
          email: "yamada@example.com",
          password: "password123"
        }
      ]
    })
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("ユーザーが見つかりません", status: :not_found)
  end

  def user_params
    params.require(:user).permit(:name, :user_type, :generation, :gender, :birthday, :introduction)
  end

  def user_auth_params
    return {} unless params[:user_auth].present?
    
    permitted = params.require(:user_auth).permit(:email)
    
    # パスワードが提供されている場合のみ含める
    if params[:user_auth][:password].present?
      permitted.merge!(
        params.require(:user_auth).permit(:password, :password_confirmation)
      )
    end
    
    permitted
  end

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      user_type: user.user_type,
      user_type_label: user.user_type.humanize,
      generation: user.generation,
      gender: user.gender,
      gender_label: user.gender&.humanize,
      birthday: user.birthday,
      bio: user.bio,
      created_at: user.created_at,
      updated_at: user.updated_at,
      email: user.user_auth&.email,
      profile_image_url: user.profile_image_url&.present? ? url_for(user.profile_image_url) : nil
    }
  end

  def serialize_user_detail(user)
    serialize_user(user).merge({
      records_count: user.records.count,
      objectives_count: user.objectives.count,
      attendances_count: user.attendances.count,
      last_login_at: user.user_auth&.last_sign_in_at,
      sign_in_count: user.user_auth&.sign_in_count || 0
    })
  end



  def validate_import_user_data(data)
    errors = []
    
    errors << "名前が必須です" if data[:name].blank?
    errors << "ユーザータイプが必須です" if data[:user_type].blank?
    errors << "世代が必須です" if data[:generation].blank?
    errors << "性別が必須です" if data[:gender].blank?
    errors << "メールアドレスが必須です" if data[:email].blank?
    
    # 有効な値の検証
    unless User.user_types.key?(data[:user_type].to_s)
      errors << "無効なユーザータイプです"
    end
    
    unless User.genders.key?(data[:gender].to_s)
      errors << "無効な性別です"
    end
    
    if data[:generation].present? && (!data[:generation].is_a?(Numeric) || data[:generation] <= 0)
      errors << "世代は正の数値である必要があります"
    end
    
    if data[:email].present? && !data[:email].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      errors << "メールアドレスの形式が正しくありません"
    end
    
    # 重複チェック
    if data[:email].present? && UserAuth.exists?(email: data[:email])
      errors << "このメールアドレスは既に使用されています"
    end
    
    errors
  end

  # インポートデータの署名付きトークンを生成
  def generate_import_token(data)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    verifier.generate(data, expires_in: 1.hour)
  end

  # インポートトークンを検証・デコード
  def verify_import_token(token)
    verifier = ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
    verifier.verify(token)
  end
end
