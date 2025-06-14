class MemberController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @users = User.all.sort_by { |user| [ user.generation, user.name ] }
    @grouped_by_generation = @users.group_by { |user| user.generation }

    # ユーザータイプの表示順序を定義
    type_order = { "player" => 0, "coach" => 1, "director" => 2 }
    @grouped_by_type = @users.group_by { |user| user.user_type }
                            .sort_by { |type, _| type_order[type] || 3 }
                            .to_h
  end
end
