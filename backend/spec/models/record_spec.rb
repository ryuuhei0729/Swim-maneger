require 'rails_helper'

RSpec.describe Record, type: :model do
  let(:user) { create(:user) }
  let(:style) { create(:style) }

  describe 'バリデーション' do
    let(:record) { build(:record, user: user, style: style) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(record).to be_valid
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        record_without_user = build(:record, user: nil, style: style)
        expect(record_without_user).not_to be_valid
        expect(record_without_user.errors[:user]).to be_present
      end
    end

    context 'style_idが空の場合' do
      it '無効であること' do
        record_without_style = build(:record, user: user, style: nil)
        expect(record_without_style).not_to be_valid
        expect(record_without_style.errors[:style]).to be_present
      end
    end

    context 'timeが空の場合' do
      it '無効であること' do
        record.time = nil
        expect(record).not_to be_valid
        expect(record.errors[:time]).to include("を入力してください")
      end
    end

    context 'timeが0以下の場合' do
      it '無効であること' do
        record.time = 0
        expect(record).not_to be_valid
        expect(record.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'timeが負の値の場合' do
      it '無効であること' do
        record.time = -1
        expect(record).not_to be_valid
        expect(record.errors[:time]).to include("は0より大きい値にしてください")
      end
    end

    context 'video_urlが無効な形式の場合' do
      it '無効であること' do
        record.video_url = "invalid-url"
        expect(record).not_to be_valid
        expect(record.errors[:video_url]).to include("は正しい形式で入力してください")
      end
    end

    context 'video_urlが有効な形式の場合' do
      it '有効であること' do
        record_with_youtube = build(:record, user: user, style: style, video_url: "https://www.youtube.com/watch?v=example")
        expect(record_with_youtube).to be_valid
      end

      it 'httpでも有効であること' do
        record_with_http = build(:record, user: user, style: style, video_url: "http://example.com/video.mp4")
        expect(record_with_http).to be_valid
      end
    end

    context 'video_urlが空の場合' do
      it '有効であること' do
        record_without_url = build(:record, user: user, style: style, video_url: nil)
        expect(record_without_url).to be_valid
      end

      it '空文字でも有効であること' do
        record_with_empty_url = build(:record, user: user, style: style, video_url: "")
        expect(record_with_empty_url).to be_valid
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      record = create(:record)
      expect(record.user).to be_present
    end

    it 'attendance_eventとの関連を持つこと' do
      record = create(:record)
      expect(record.attendance_event).to be_present
    end

    it 'styleとの関連を持つこと' do
      record = create(:record)
      expect(record.style).to be_present
    end
  end

  describe 'trait' do
    it 'fast_time traitが正しく動作すること' do
      record = build(:record, :fast_time)
      expect(record.time).to be_between(20.0, 30.0)
    end

    it 'slow_time traitが正しく動作すること' do
      record = build(:record, :slow_time)
      expect(record.time).to be_between(100.0, 120.0)
    end

    it 'with_video traitが正しく動作すること' do
      record = build(:record, :with_video)
      expect(record.video_url).to match(/^https?:\/\/.+/)
    end

    it 'without_video traitが正しく動作すること' do
      record = build(:record, :without_video)
      expect(record.video_url).to be_nil
    end

    it 'with_note traitが正しく動作すること' do
      record = build(:record, :with_note)
      expect(record.note).to be_present
    end

    it 'without_note traitが正しく動作すること' do
      record = build(:record, :without_note)
      expect(record.note).to be_nil
    end
  end

  describe 'エッジケース' do
    it '非常に大きなtimeを処理できること' do
      record = build(:record, user: user, style: style, time: 999999.99)
      expect(record).to be_valid
    end

    it '小数点を含むtimeを処理できること' do
      record = build(:record, user: user, style: style, time: 25.67)
      expect(record).to be_valid
    end

    it '非常に長いnoteを処理できること' do
      record = build(:record, user: user, style: style, note: "a" * 1000)
      expect(record).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      record = build(:record, user: user, style: style, note: "記録：\n- スタートが良かった\n- ターンで時間をロス\n- 全体的に良いレースでした")
      expect(record).to be_valid
    end

    it '複雑なvideo_urlを処理できること' do
      record = build(:record, user: user, style: style, video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=123s")
      expect(record).to be_valid
    end
  end
end
