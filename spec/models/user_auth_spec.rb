require 'rails_helper'

RSpec.describe UserAuth, type: :model do
  describe 'バリデーション' do
    let(:user_auth) { build(:user_auth) }

    context '有効な属性の場合' do
      it '有効であること' do
        expect(user_auth).to be_valid
      end
    end

    context 'emailが空の場合' do
      it '無効であること' do
        user_auth.email = nil
        expect(user_auth).not_to be_valid
        expect(user_auth.errors[:email]).to include("を入力してください")
      end
    end

    context 'emailが無効な形式の場合' do
      it '無効であること' do
        user_auth.email = "invalid-email"
        expect(user_auth).not_to be_valid
        expect(user_auth.errors[:email]).to include("は正しい形式で入力してください")
      end
    end

    context 'emailが重複している場合' do
      it '無効であること' do
        existing_user_auth = create(:user_auth)
        duplicate_user_auth = build(:user_auth, email: existing_user_auth.email)
        expect(duplicate_user_auth).not_to be_valid
        expect(duplicate_user_auth.errors[:email]).to include("はすでに存在します")
      end
    end

    context 'passwordが空の場合' do
      it '無効であること' do
        user_auth.password = nil
        expect(user_auth).not_to be_valid
        expect(user_auth.errors[:password]).to include("を入力してください")
      end
    end

    context 'passwordが短すぎる場合' do
      it '無効であること' do
        user_auth.password = "123"
        expect(user_auth).not_to be_valid
        expect(user_auth.errors[:password]).to include("は6文字以上で入力してください")
      end
    end
  end

  describe 'アソシエーション' do
    it 'userとの関連を持つこと' do
      user_auth = create(:user_auth)
      expect(user_auth.user).to be_present
    end
  end

  describe 'コールバック' do
    describe 'before_create :build_default_user' do
      context 'userが存在しない場合' do
        it 'デフォルトのuserをbuildすること' do
          user_auth = build(:user_auth, user: nil)
          user_auth.send(:build_default_user)

          expect(user_auth.user).to be_present
          expect(user_auth.user.generation).to eq(1)
          expect(user_auth.user.name).to eq(user_auth.email.split("@").first)
          expect(user_auth.user.gender).to eq("male")
          expect(user_auth.user.user_type).to eq("player")
        end
      end

      context 'userが既に存在する場合' do
        it 'build_default_userメソッドが何もしないこと' do
          existing_user = create(:user)
          user_auth = build(:user_auth, user: existing_user)
          original_user = user_auth.user
          
          user_auth.send(:build_default_user)
          
          expect(user_auth.user).to eq(original_user)
        end
      end
    end
  end

  describe 'メソッド' do
    describe '#profile_image_url' do
      it 'GravatarのURLを返すこと' do
        user_auth = build(:user_auth, email: "test@example.com")
        expected_url = "https://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('test@example.com')}?s=200&d=identicon"

        expect(user_auth.profile_image_url).to eq(expected_url)
      end
    end
  end

  describe 'trait' do
    it 'with_user traitが正しく動作すること' do
      user_auth = create(:user_auth, :with_user)
      expect(user_auth.user).to be_present
    end

    it 'without_user traitが正しく動作すること' do
      user_auth = build(:user_auth, :without_user)
      expect(user_auth.user).to be_nil
    end
  end

  describe 'Devise' do
    it 'Deviseのモジュールが含まれていること' do
      expect(UserAuth.devise_modules).to include(:database_authenticatable)
      expect(UserAuth.devise_modules).to include(:registerable)
      expect(UserAuth.devise_modules).to include(:recoverable)
      expect(UserAuth.devise_modules).to include(:rememberable)
      expect(UserAuth.devise_modules).to include(:validatable)
    end
  end

  describe 'エッジケース' do
    it '非常に長いemailを処理できること' do
      user_auth = build(:user_auth, email: "a" * 100 + "@example.com")
      expect(user_auth).to be_valid
    end

    it '特殊文字を含むemailを処理できること' do
      user_auth = build(:user_auth, email: "test+tag@example.com")
      expect(user_auth).to be_valid
    end

    it '非常に長いpasswordを処理できること' do
      long_password = "a" * 98 + "1" + "A"
      user_auth = build(:user_auth, password: long_password, password_confirmation: long_password)
      expect(user_auth).to be_valid
    end
  end
end
