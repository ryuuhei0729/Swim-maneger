module SanitizationHelper
  # HTMLタグを除去してテキストのみを抽出
  def sanitize_html(text)
    return "" if text.blank?
    
    # Railsの標準サニタイザーを使用してHTMLを安全に除去
    ActionView::Base.full_sanitizer.sanitize(text.to_s)
  end

  # SQLインジェクション対策用の文字列エスケープ
  def escape_sql_like(string, escape_character = "\\")
    return nil if string.blank?
    
    ActiveRecord::Base.sanitize_sql_like(string, escape_character)
  end

  # ファイル名のサニタイゼーション
  def sanitize_filename(filename)
    return nil if filename.blank?
    
    # 危険な文字を除去
    filename.gsub(/[^0-9A-Za-z.\-_]/, '_')
            .gsub(/_{2,}/, '_')
            .gsub(/^_|_$/, '')
  end

  # メールアドレスの検証
  def valid_email?(email)
    return false if email.blank?
    
    email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    email.match?(email_regex)
  end

  # 電話番号の検証
  def valid_phone?(phone)
    return false if phone.blank?
    
    # 日本の電話番号形式（ハイフンありなし両方対応）
    phone_regex = /\A(\+81|0)[0-9\-]{9,15}\z/
    phone.match?(phone_regex)
  end

  # 日付の検証
  def valid_date?(date_string)
    return false if date_string.blank?
    
    begin
      Date.parse(date_string)
      true
    rescue ArgumentError
      false
    end
  end

  # 数値の検証
  def valid_number?(number_string)
    return false if number_string.blank?
    
    number_string.match?(/\A\d+(\.\d+)?\z/)
  end

  # XSS対策用のHTMLエスケープ
  def escape_html(text)
    return "" if text.blank?
    
    ERB::Util.html_escape(text.to_s)
  end

  # パスワード強度の検証
  def strong_password?(password)
    return false if password.blank? || password.length < 8
    
    # 英大文字、英小文字、数字を含むかチェック
    has_uppercase = password.match?(/[A-Z]/)
    has_lowercase = password.match?(/[a-z]/)
    has_digit = password.match?(/\d/)
    
    has_uppercase && has_lowercase && has_digit
  end

  # ファイルサイズの検証
  def valid_file_size?(file_size, max_size_mb = 10)
    return false if file_size.blank?
    
    file_size <= max_size_mb.megabytes
  end

  # ファイルタイプの検証
  def valid_file_type?(filename, allowed_extensions = %w[jpg jpeg png gif pdf doc docx xls xlsx])
    return false if filename.blank?
    
    extension = File.extname(filename).downcase.gsub('.', '')
    allowed_extensions.include?(extension)
  end
end
