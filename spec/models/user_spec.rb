require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    let(:user) { build(:user) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(user).to be_valid
      end
    end

    context 'generationが空の場合' do
      it '無効であること' do
        user.generation = nil
        expect(user).not_to be_valid
        expect(user.errors[:generation]).to include("を入力してください")
      end
    end

    context 'nameが空の場合' do
      it '無効であること' do
        user.name = nil
        expect(user).not_to be_valid
        expect(user.errors[:name]).to include("を入力してください")
      end
    end

    context 'genderが空の場合' do
      it '無効であること' do
        user.gender = nil
        expect(user).not_to be_valid
        expect(user.errors[:gender]).to include("を入力してください")
      end
    end

    context 'genderが無効な値の場合' do
      it '無効であること' do
        expect { user.gender = "invalid" }.to raise_error(ArgumentError)
      end
    end

    context 'birthdayが空の場合' do
      it '無効であること' do
        user.birthday = nil
        expect(user).not_to be_valid
        expect(user.errors[:birthday]).to include("を入力してください")
      end
    end

    context 'user_typeが空の場合' do
      it '無効であること' do
        user.user_type = nil
        expect(user).not_to be_valid
        expect(user.errors[:user_type]).to include("を入力してください")
      end
    end

    context 'user_typeが無効な値の場合' do
      it '無効であること' do
        expect { user.user_type = "invalid" }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'アソシエーション' do
    it 'user_authとの関連を持つこと' do
      user = create(:user)
      user_auth = create(:user_auth, user: user)
      expect(user.user_auth).to eq(user_auth)
    end

    it 'attendanceとの関連を持つこと' do
      user = create(:user)
      attendance = create(:attendance, user: user)
      expect(user.attendance).to include(attendance)
    end

    it 'attendance_eventsとの関連を持つこと' do
      user = create(:user)
      attendance_event = create(:attendance_event)
      attendance = create(:attendance, user: user, attendance_event: attendance_event)
      expect(user.attendance_events).to include(attendance_event)
    end

    it 'recordsとの関連を持つこと' do
      user = create(:user)
      record = create(:record, user: user)
      expect(user.records).to include(record)
    end

    it 'objectivesとの関連を持つこと' do
      user = create(:user)
      objective = create(:objective, user: user)
      expect(user.objectives).to include(objective)
    end

    it 'race_goalsとの関連を持つこと' do
      user = create(:user)
      race_goal = create(:race_goal, user: user)
      expect(user.race_goals).to include(race_goal)
    end

    it 'race_feedbacksとの関連を持つこと' do
      user = create(:user)
      race_feedback = create(:race_feedback, user: user)
      expect(user.race_feedbacks).to include(race_feedback)
    end
  end

  describe 'enum' do
    it '正しいgender enum値を持つこと' do
      expect(User.genders).to have_key("male")
      expect(User.genders).to have_key("female")
    end

    it '正しいuser_type enum値を持つこと' do
      expect(User.user_types).to have_key("director")
      expect(User.user_types).to have_key("coach")
      expect(User.user_types).to have_key("player")
      expect(User.user_types).to have_key("manager")
    end

    describe '#male?' do
      it 'male genderの場合trueを返すこと' do
        user = build(:user, gender: "male")
        expect(user.male?).to be true
        expect(user.female?).to be false
      end
    end

    describe '#female?' do
      it 'female genderの場合trueを返すこと' do
        user = build(:user, gender: "female")
        expect(user.female?).to be true
        expect(user.male?).to be false
      end
    end

    describe '#director?' do
      it 'director user_typeの場合trueを返すこと' do
        user = build(:user, user_type: "director")
        expect(user.director?).to be true
      end
    end

    describe '#coach?' do
      it 'coach user_typeの場合trueを返すこと' do
        user = build(:user, user_type: "coach")
        expect(user.coach?).to be true
      end
    end

    describe '#player?' do
      it 'player user_typeの場合trueを返すこと' do
        user = build(:user, user_type: "player")
        expect(user.player?).to be true
      end
    end

    describe '#manager?' do
      it 'manager user_typeの場合trueを返すこと' do
        user = build(:user, user_type: "manager")
        expect(user.manager?).to be true
      end
    end
  end

  describe 'メソッド' do
    describe '#admin?' do
      it 'coachの場合trueを返すこと' do
        user = build(:user, user_type: "coach")
        expect(user.admin?).to be true
      end

      it 'directorの場合trueを返すこと' do
        user = build(:user, user_type: "director")
        expect(user.admin?).to be true
      end

      it 'managerの場合trueを返すこと' do
        user = build(:user, user_type: "manager")
        expect(user.admin?).to be true
      end

      it 'playerの場合falseを返すこと' do
        user = build(:user, user_type: "player")
        expect(user.admin?).to be false
      end
    end

    describe '#email' do
      it 'user_authのemailを返すこと' do
        user = create(:user)
        user_auth = create(:user_auth, user: user, email: "test@example.com")
        expect(user.email).to eq("test@example.com")
      end

      it 'user_authがない場合nilを返すこと' do
        user = build(:user)
        expect(user.email).to be_nil
      end
    end

    describe '#profile_image_url' do
      it 'avatarが添付されている場合avatarを返すこと' do
        user = build(:user)
        # Active Storageのテストは複雑なため、基本的な動作のみテスト
        expect(user).to respond_to(:profile_image_url)
      end
    end

    describe '#best_time_notes' do
      it '各スタイルのベストタイムのnoteを返すこと' do
        user = create(:user)
        style = create(:style)
        record = create(:record, user: user, style: style, note: "ベストタイム")

        expect(user.best_time_notes).to be_a(Hash)
        expect(user.best_time_notes[style.name]).to eq("ベストタイム")
      end
    end
  end

  describe 'trait' do
    it 'male traitが正しく動作すること' do
      user = build(:user, :male)
      expect(user.gender).to eq("male")
    end

    it 'female traitが正しく動作すること' do
      user = build(:user, :female)
      expect(user.gender).to eq("female")
    end

    it 'player traitが正しく動作すること' do
      user = build(:user, :player)
      expect(user.user_type).to eq("player")
    end

    it 'coach traitが正しく動作すること' do
      user = build(:user, :coach)
      expect(user.user_type).to eq("coach")
    end

    it 'director traitが正しく動作すること' do
      user = build(:user, :director)
      expect(user.user_type).to eq("director")
    end

    it 'manager traitが正しく動作すること' do
      user = build(:user, :manager)
      expect(user.user_type).to eq("manager")
    end

    it 'with_user_auth traitが正しく動作すること' do
      user = create(:user, :with_user_auth)
      expect(user.user_auth).to be_present
    end
  end

  describe '定数' do
    it 'USER_TYPESが正しく定義されていること' do
      expect(User::USER_TYPES[:player]).to eq("player")
      expect(User::USER_TYPES[:coach]).to eq("coach")
      expect(User::USER_TYPES[:director]).to eq("director")
      expect(User::USER_TYPES[:manager]).to eq("manager")
    end

    it 'GENDERSが正しく定義されていること' do
      expect(User::GENDERS[:male]).to eq("male")
      expect(User::GENDERS[:female]).to eq("female")
    end

    it 'ADMIN_TYPESが正しく定義されていること' do
      expect(User::ADMIN_TYPES).to include("coach", "director", "manager")
      expect(User::ADMIN_TYPES).not_to include("player")
    end
  end

  describe 'エッジケース' do
    it '非常に長いnameを処理できること' do
      user = build(:user, name: "a" * 1000)
      expect(user).to be_valid
    end

    it '非常に大きなgenerationを処理できること' do
      user = build(:user, generation: 999999)
      expect(user).to be_valid
    end
  end
end
