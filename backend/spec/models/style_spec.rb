require 'rails_helper'

RSpec.describe Style, type: :model do
  describe 'バリデーション' do
    let(:style) { build(:style) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(style).to be_valid
      end
    end

    context 'name_jpが空の場合' do
      it '無効であること' do
        style.name_jp = nil
        expect(style).not_to be_valid
        expect(style.errors[:name_jp]).to include("を入力してください")
      end
    end

    context 'name_jpが重複している場合' do
      it '無効であること' do
        existing_style = create(:style)
        duplicate_style = build(:style, name_jp: existing_style.name_jp)
        expect(duplicate_style).not_to be_valid
        expect(duplicate_style.errors[:name_jp]).to include("はすでに存在します")
      end
    end

    context 'nameが空の場合' do
      it '無効であること' do
        style.name = nil
        expect(style).not_to be_valid
        expect(style.errors[:name]).to include("を入力してください")
      end
    end

    context 'nameが重複している場合' do
      it '無効であること' do
        existing_style = create(:style)
        duplicate_style = build(:style, name: existing_style.name)
        expect(duplicate_style).not_to be_valid
        expect(duplicate_style.errors[:name]).to include("はすでに存在します")
      end
    end

    context 'styleが空の場合' do
      it '無効であること' do
        style.style = nil
        expect(style).not_to be_valid
        expect(style.errors[:style]).to include("を入力してください")
      end
    end

    context 'styleが無効な値の場合' do
      it '無効であること' do
        expect { style.style = "invalid" }.to raise_error(ArgumentError)
      end
    end

    context 'distanceが空の場合' do
      it '無効であること' do
        style.distance = nil
        expect(style).not_to be_valid
        expect(style.errors[:distance]).to include("を入力してください")
      end
    end

    context 'distanceが0以下の場合' do
      it '無効であること' do
        style.distance = 0
        expect(style).not_to be_valid
        expect(style.errors[:distance]).to include("は0より大きい値にしてください")
      end
    end

    context 'distanceが負の値の場合' do
      it '無効であること' do
        style.distance = -1
        expect(style).not_to be_valid
        expect(style.errors[:distance]).to include("は0より大きい値にしてください")
      end
    end

    context 'distanceが整数でない場合' do
      it '無効であること' do
        style.distance = 50.5
        expect(style).not_to be_valid
        expect(style.errors[:distance]).to be_present
      end
    end
  end

  describe 'アソシエーション' do
    it 'recordsとの関連を持つこと' do
      style = create(:style)
      record = create(:record, style: style)
      expect(style.records).to include(record)
    end

    it 'objectivesとの関連を持つこと' do
      style = create(:style)
      objective = create(:objective, style: style)
      expect(style.objectives).to include(objective)
    end

    it 'race_goalsとの関連を持つこと' do
      style = create(:style)
      race_goal = create(:race_goal, style: style)
      expect(style.race_goals).to include(race_goal)
    end

    it 'race_reviewsとの関連を持つこと' do
      style = create(:style)
      race_review = create(:race_review, style: style)
      expect(style.race_reviews).to include(race_review)
    end
  end

  describe 'enum' do
    it '正しいstyle enum値を持つこと' do
      expect(Style.styles).to include("fr")
      expect(Style.styles).to include("br")
      expect(Style.styles).to include("ba")
      expect(Style.styles).to include("fly")
      expect(Style.styles).to include("im")
    end

    describe '#fr?' do
      it 'fr styleの場合trueを返すこと' do
        style = build(:style, style: "fr")
        expect(style.fr?).to be true
        expect(style.br?).to be false
      end
    end

    describe '#br?' do
      it 'br styleの場合trueを返すこと' do
        style = build(:style, style: "br")
        expect(style.br?).to be true
        expect(style.fr?).to be false
      end
    end

    describe '#ba?' do
      it 'ba styleの場合trueを返すこと' do
        style = build(:style, style: "ba")
        expect(style.ba?).to be true
        expect(style.fr?).to be false
      end
    end

    describe '#fly?' do
      it 'fly styleの場合trueを返すこと' do
        style = build(:style, style: "fly")
        expect(style.fly?).to be true
        expect(style.fr?).to be false
      end
    end

    describe '#im?' do
      it 'im styleの場合trueを返すこと' do
        style = build(:style, style: "im")
        expect(style.im?).to be true
        expect(style.fr?).to be false
      end
    end
  end

  describe 'クラスメソッド' do
    describe '.styles' do
      it '有効なスタイルの配列を返すこと' do
        expect(Style.styles.keys).to eq([ "fr", "br", "ba", "fly", "im" ])
      end
    end
  end

  describe 'trait' do
    it 'freestyle traitが正しく動作すること' do
      style = build(:style, :freestyle)
      expect(style.style).to eq("fr")
    end

    it 'breaststroke traitが正しく動作すること' do
      style = build(:style, :breaststroke)
      expect(style.style).to eq("br")
    end

    it 'backstroke traitが正しく動作すること' do
      style = build(:style, :backstroke)
      expect(style.style).to eq("ba")
    end

    it 'butterfly traitが正しく動作すること' do
      style = build(:style, :butterfly)
      expect(style.style).to eq("fly")
    end

    it 'individual_medley traitが正しく動作すること' do
      style = build(:style, :individual_medley)
      expect(style.style).to eq("im")
    end

    it 'short_distance traitが正しく動作すること' do
      style = build(:style, :short_distance)
      expect(style.distance).to be_between(25, 100)
    end

    it 'long_distance traitが正しく動作すること' do
      style = build(:style, :long_distance)
      expect(style.distance).to be_between(200, 800)
    end
  end

  describe 'エッジケース' do
    it '非常に大きなdistanceを処理できること' do
      style = build(:style, distance: 999999)
      expect(style).to be_valid
    end

    it '非常に長いnameを処理できること' do
      style = build(:style, name: "a" * 1000)
      expect(style).to be_valid
    end

    it '非常に長いname_jpを処理できること' do
      style = build(:style, name_jp: "a" * 1000)
      expect(style).to be_valid
    end
  end
end
