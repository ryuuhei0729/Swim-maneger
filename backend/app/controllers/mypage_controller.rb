class MypageController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @user = current_user_auth.user
    @records = @user.records.includes(:style, :attendance_event).order(created_at: :desc)

    # 各種目のベストタイムを取得（事前に記録をロードしてN+1クエリを回避）
    @best_times = {}
    styles_with_records = @records.group_by(&:style)
    
    Style.all.each do |style|
      style_records = styles_with_records[style] || []
      best_record = style_records.min_by(&:time)
      @best_times[style.name] = best_record&.time
    end
  end

  def update
    @user = current_user_auth.user

    # 画像形式のチェック
    if params[:user][:avatar].present?
      content_type = params[:user][:avatar].content_type
      unless [ "image/jpeg", "image/png" ].include?(content_type)
        redirect_to mypage_path, alert: "JPGまたはPNG形式の画像のみアップロード可能です"
        return
      end
    end

    if @user.update(user_params)
      redirect_to mypage_path, notice: "プロフィールを更新しました"
    else
      redirect_to mypage_path, alert: "プロフィールの更新に失敗しました"
    end
  end

  private

  def user_params
    params.require(:user).permit(:bio, :avatar)
  end
end
