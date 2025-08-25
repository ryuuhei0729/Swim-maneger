class Admin::AnnouncementsController < Admin::BaseController
  def index
    @announcements = Announcement.all.order(published_at: :desc)
    @announcement = Announcement.new
  end

  def create
    @announcement = Announcement.new(announcement_params)

    if @announcement.save
      redirect_to admin_announcement_path, notice: "お知らせを作成しました。"
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @announcement = Announcement.find(params[:id])

    if @announcement.update(announcement_params)
      redirect_to admin_announcement_path, notice: "お知らせを更新しました。"
    else
      @announcements = Announcement.all.order(published_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement = Announcement.find(params[:id])
    @announcement.destroy

    redirect_to admin_announcement_path, notice: "お知らせを削除しました。"
  end

  private

  def announcement_params
    params.require(:announcement).permit(:title, :content, :is_active, :published_at)
  end
end 