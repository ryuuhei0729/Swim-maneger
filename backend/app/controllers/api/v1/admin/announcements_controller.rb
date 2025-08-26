class Api::V1::Admin::AnnouncementsController < Api::V1::BaseController
  before_action :check_admin_access
  before_action :set_announcement, only: [:show, :update, :destroy]

  # GET /api/v1/admin/announcements
  def index
    announcements = Announcement.all.order(published_at: :desc)
    
    render_success({
      announcements: announcements.map { |announcement| serialize_announcement(announcement) },
      total_count: announcements.count,
      active_count: announcements.where(is_active: true).count,
      inactive_count: announcements.where(is_active: false).count
    })
  end

  # GET /api/v1/admin/announcements/:id
  def show
    render_success({
      announcement: serialize_announcement_detail(@announcement)
    })
  end

  # POST /api/v1/admin/announcements
  def create
    announcement = Announcement.new(announcement_params)

    if announcement.save
      render_success({
        announcement: serialize_announcement(announcement)
      }, "お知らせを作成しました", :created)
    else
      render_error("お知らせの作成に失敗しました", :unprocessable_entity, announcement.errors.as_json)
    end
  end

  # PATCH /api/v1/admin/announcements/:id
  def update
    if @announcement.update(announcement_params)
      render_success({
        announcement: serialize_announcement(@announcement)
      }, "お知らせを更新しました")
    else
      render_error("お知らせの更新に失敗しました", :unprocessable_entity, @announcement.errors.as_json)
    end
  end

  # DELETE /api/v1/admin/announcements/:id
  def destroy
    @announcement.destroy
    render_success({}, "お知らせを削除しました")
  end

  # PATCH /api/v1/admin/announcements/:id/toggle_active
  def toggle_active
    set_announcement
    
    @announcement.update!(is_active: !@announcement.is_active)
    
    status_message = @announcement.is_active? ? "公開" : "非公開"
    render_success({
      announcement: serialize_announcement(@announcement)
    }, "お知らせを#{status_message}にしました")
  end

  # POST /api/v1/admin/announcements/bulk_action
  def bulk_action
    unless params[:action_type].present? && params[:announcement_ids].present?
      return render_error("必要なパラメータが不足しています", :bad_request)
    end

    action_type = params[:action_type]
    announcement_ids = params[:announcement_ids].map(&:to_i)
    announcements = Announcement.where(id: announcement_ids)

    case action_type
    when 'activate'
      announcements.update_all(is_active: true)
      render_success({
        updated_count: announcements.count
      }, "#{announcements.count}件のお知らせを公開しました")
      
    when 'deactivate'
      announcements.update_all(is_active: false)
      render_success({
        updated_count: announcements.count
      }, "#{announcements.count}件のお知らせを非公開にしました")
      
    when 'delete'
      destroyed_count = announcements.count
      announcements.destroy_all
      render_success({
        deleted_count: destroyed_count
      }, "#{destroyed_count}件のお知らせを削除しました")
      
    else
      render_error("無効なアクションタイプです", :bad_request)
    end
  end

  # GET /api/v1/admin/announcements/statistics
  def statistics
    total_count = Announcement.count
    active_count = Announcement.where(is_active: true).count
    inactive_count = Announcement.where(is_active: false).count
    
    # 最近の活動（週別）
    recent_announcements = Announcement.where(created_at: 1.month.ago..Time.current)
                                     .group("DATE_TRUNC('week', created_at)")
                                     .count
    
    # 月別統計
    monthly_stats = Announcement.where(created_at: 6.months.ago..Time.current)
                               .group("DATE_TRUNC('month', created_at)")
                               .count
    
    render_success({
      total_count: total_count,
      active_count: active_count,
      inactive_count: inactive_count,
      recent_activity: recent_announcements,
      monthly_stats: monthly_stats,
      latest_announcement: Announcement.order(created_at: :desc).first&.then { |a| serialize_announcement(a) }
    })
  end

  private

  def check_admin_access
    unless current_user_auth.user.user_type.in?(["coach", "director", "manager"])
      render_error("管理者権限が必要です", :forbidden)
    end
  end

  def set_announcement
    @announcement = Announcement.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("お知らせが見つかりません", :not_found)
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :is_active, :published_at)
  end

  def serialize_announcement(announcement)
    {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      is_active: announcement.is_active,
      published_at: announcement.published_at,
      created_at: announcement.created_at,
      updated_at: announcement.updated_at,
      content_preview: truncate_content(announcement.content, 100),
      status_label: announcement.is_active? ? "公開中" : "非公開"
    }
  end

  def serialize_announcement_detail(announcement)
    serialize_announcement(announcement).merge({
      content_length: announcement.content&.length || 0,
      days_since_published: announcement.published_at ? (Date.current - announcement.published_at.to_date).to_i : nil,
      is_recent: announcement.created_at > 1.week.ago
    })
  end

  def truncate_content(content, length)
    return "" if content.blank?
    
    if content.length > length
      content[0...length] + "..."
    else
      content
    end
  end
end
