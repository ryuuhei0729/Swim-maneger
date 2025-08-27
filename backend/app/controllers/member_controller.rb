class MemberController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    # キャッシュを使用してユーザー一覧を取得
    @users, @grouped_by_generation, @grouped_by_type, @user_best_records = CacheService.cache_users_list do
      # Eager loadingでN+1クエリを解決し、必要なレコードも事前取得
      users = User.includes(records: :style).order(:generation, :name)
      grouped_by_generation = users.group_by { |user| user.generation }

      # ユーザータイプの表示順序を定義（User enumの順序に合わせる）
      grouped_by_type = users.group_by { |user| user.user_type }
                              .sort_by { |type, _| User.user_types[type] || 999 }
                              .to_h

      # 各ユーザーの各種目のベストタイムを事前に計算してハッシュ化
      user_best_records = {}
      users.each do |user|
        user_best_records[user.id] = {}
        user.records.group_by(&:style_id).each do |style_id, records|
          user_best_records[user.id][style_id] = records.min_by(&:time)
        end
      end

      [users, grouped_by_generation, grouped_by_type, user_best_records]
    end
  end
end
