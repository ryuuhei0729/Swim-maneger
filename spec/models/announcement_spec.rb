require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe 'バリデーション' do
    let(:announcement) { build(:announcement) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(announcement).to be_valid
      end
    end

    context 'titleが空の場合' do
      it '無効であること' do
        announcement.title = nil
        expect(announcement).not_to be_valid
        expect(announcement.errors[:title]).to include("を入力してください")
      end
    end

    context 'contentが空の場合' do
      it '無効であること' do
        announcement.content = nil
        expect(announcement).not_to be_valid
        expect(announcement.errors[:content]).to include("を入力してください")
      end
    end

    context 'published_atが空の場合' do
      it '保存時に自動で現在時刻が設定されること' do
        announcement = build(:announcement)
        announcement.published_at = nil
        announcement.save!
        expect(announcement.published_at).to be_present
      end
    end

    context 'is_activeが空の場合' do
      it '無効であること' do
        announcement.is_active = nil
        expect(announcement).not_to be_valid
        expect(announcement.errors[:is_active]).to include("は一覧にありません")
      end
    end

    context 'published_atが過去の場合' do
      it '無効であること' do
        announcement.published_at = Time.current - 1.minute
        expect(announcement).not_to be_valid
        expect(announcement.errors[:published_at]).to include("は現在日時以降を指定してください")
      end
    end
  end

  describe 'アソシエーション' do
    # Announcementモデルには特別なアソシエーションはない
    it '基本的なモデルとして機能すること' do
      announcement = create(:announcement)
      expect(announcement).to be_persisted
    end
  end

  describe 'trait' do
    it 'published traitが正しく動作すること' do
      announcement = build(:announcement, :published)
      expect(announcement.published_at).to be_within(1.second).of(Time.current)
    end

    it 'unpublished traitが正しく動作すること' do
      announcement = build(:announcement, :unpublished)
      expect(announcement.published_at).to be > Time.current
    end

    it 'with_long_content traitが正しく動作すること' do
      announcement = build(:announcement, :with_long_content)
      expect(announcement.content.length).to eq(1000)
    end

    it 'with_short_content traitが正しく動作すること' do
      announcement = build(:announcement, :with_short_content)
      expect(announcement.content.length).to be_between(10, 100)
    end

    it 'inactive traitが正しく動作すること' do
      announcement = build(:announcement, :inactive)
      expect(announcement.is_active).to be false
    end
  end

  describe 'スコープ' do
    describe '.active' do
      it 'アクティブなお知らせのみを返すこと' do
        active_announcement = create(:announcement, is_active: true)
        inactive_announcement = create(:announcement, :inactive)

        active_announcements = Announcement.active
        expect(active_announcements).to include(active_announcement)
        expect(active_announcements).not_to include(inactive_announcement)
      end
    end

    describe '.published' do
      it '現在以降のpublished_atを持つお知らせのみを返すこと' do
        published_announcement = create(:announcement, :published)
        future_announcement = create(:announcement, :unpublished)

        published_announcements = Announcement.published
        expect(published_announcements).to include(published_announcement)
        expect(published_announcements).not_to include(future_announcement)
      end
    end

    describe '.recent' do
      it 'published_atの降順で取得すること' do
        announcement1 = create(:announcement, published_at: Time.current + 2.hours)
        announcement2 = create(:announcement, published_at: Time.current + 1.hour)
        recent_announcements = Announcement.recent
        expect(recent_announcements.first).to eq(announcement1)
        expect(recent_announcements.second).to eq(announcement2)
      end
    end
  end

  describe 'コールバック' do
    it '作成時にpublished_atが自動設定されること' do
      announcement = build(:announcement, published_at: nil)
      announcement.save!
      expect(announcement.published_at).to be_present
    end
  end

  describe 'エッジケース' do
    it '非常に長いtitleを処理できること' do
      announcement = build(:announcement, title: "a" * 1000)
      expect(announcement).to be_valid
    end

    it '非常に長いcontentを処理できること' do
      announcement = build(:announcement, content: "a" * 1000)
      expect(announcement).to be_valid
    end

    it '特殊文字を含むcontentを処理できること' do
      announcement = build(:announcement, 
        title: "重要なお知らせ",
        content: "お知らせ内容：\n- 練習時間の変更\n- 大会の日程\n- 注意事項について"
      )
      expect(announcement).to be_valid
    end

    it '現在時刻のpublished_atを設定できること' do
      announcement = build(:announcement, published_at: Time.current)
      expect(announcement).to be_valid
    end

    it '未来のpublished_atを設定できること' do
      announcement = build(:announcement, published_at: 1.month.from_now)
      expect(announcement).to be_valid
    end
  end
end 