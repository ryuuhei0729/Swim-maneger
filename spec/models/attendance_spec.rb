require 'rails_helper'

RSpec.describe Attendance, type: :model do
  describe 'バリデーション' do
    let(:attendance) { build(:attendance) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(attendance).to be_valid
      end
    end

    context 'statusが空の場合' do
      it '無効であること' do
        attendance.status = nil
        expect(attendance).not_to be_valid
        expect(attendance.errors[:status]).to include("を入力してください")
      end
    end

    context 'user_idが空の場合' do
      it '無効であること' do
        attendance.user_id = nil
        expect(attendance).not_to be_valid
        expect(attendance.errors[:user]).to include("を入力してください")
      end
    end

    context 'attendance_event_idが空の場合' do
      it '無効であること' do
        attendance.attendance_event_id = nil
        expect(attendance).not_to be_valid
        expect(attendance.errors[:attendance_event]).to include("を入力してください")
      end
    end

    context 'user_idとattendance_event_idの組み合わせが重複している場合' do
      it '無効であること' do
        existing_attendance = create(:attendance)
        duplicate_attendance = build(:attendance, 
          user: existing_attendance.user,
          attendance_event: existing_attendance.attendance_event
        )
        expect(duplicate_attendance).not_to be_valid
        expect(duplicate_attendance.errors[:user_id]).to include("はすでに存在します")
      end
    end

    context 'statusが無効な値の場合' do
      it '無効であること' do
        expect { attendance.status = "invalid" }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'カスタムバリデーション' do
    context 'absent statusの場合' do
      it 'noteが必要であること' do
        attendance = build(:attendance, :absent, note: nil)
        expect(attendance).not_to be_valid
        expect(attendance.errors[:note]).to include("欠席またはその他の場合は理由を入力してください")
      end

      it 'noteがある場合は有効であること' do
        attendance = build(:attendance, :absent, note: "体調不良")
        expect(attendance).to be_valid
      end
    end

    context 'other statusの場合' do
      it 'noteが必要であること' do
        attendance = build(:attendance, :other, note: nil)
        expect(attendance).not_to be_valid
        expect(attendance.errors[:note]).to include("欠席またはその他の場合は理由を入力してください")
      end

      it 'noteがある場合は有効であること' do
        attendance = build(:attendance, :other, note: "その他の理由")
        expect(attendance).to be_valid
      end
    end

    context 'present statusの場合' do
      it 'noteがなくても有効であること' do
        attendance = build(:attendance, :present, note: nil)
        expect(attendance).to be_valid
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      attendance = create(:attendance)
      expect(attendance.user).to be_present
    end

    it 'attendance_eventとの関連を持つこと' do
      attendance = create(:attendance)
      expect(attendance.attendance_event).to be_present
    end
  end

  describe 'enum' do
    it '正しいstatus enum値を持つこと' do
      expect(Attendance.statuses).to have_key("present")
      expect(Attendance.statuses).to have_key("absent")
      expect(Attendance.statuses).to have_key("other")
    end

    describe '#present?' do
      it 'present statusの場合trueを返すこと' do
        attendance = build(:attendance, status: "present")
        expect(attendance.present?).to be true
        expect(attendance.absent?).to be false
      end
    end

    describe '#absent?' do
      it 'absent statusの場合trueを返すこと' do
        attendance = build(:attendance, status: "absent")
        expect(attendance.absent?).to be true
        expect(attendance.present?).to be false
      end
    end

    describe '#other?' do
      it 'other statusの場合trueを返すこと' do
        attendance = build(:attendance, status: "other")
        expect(attendance.other?).to be true
        expect(attendance.present?).to be false
      end
    end
  end

  describe 'trait' do
    it 'present traitが正しく動作すること' do
      attendance = build(:attendance, :present)
      expect(attendance.status).to eq("present")
    end

    it 'absent traitが正しく動作すること' do
      attendance = build(:attendance, :absent)
      expect(attendance.status).to eq("absent")
    end

    it 'other traitが正しく動作すること' do
      attendance = build(:attendance, :other)
      expect(attendance.status).to eq("other")
    end
  end

  describe 'エッジケース' do
    it '非常に長いnoteを処理できること' do
      attendance = build(:attendance, note: "a" * 1000)
      expect(attendance).to be_valid
    end

    it '特殊文字を含むnoteを処理できること' do
      attendance = build(:attendance, note: "欠席理由：\n- 体調不良\n- ご迷惑をおかけします")
      expect(attendance).to be_valid
    end
  end
end 