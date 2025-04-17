class MemberController < ApplicationController
  before_action :authenticate_user_auth!

  def index
    @users = User.all.sort_by { |user| [user.generation, user.name] }
    @grouped_by_generation = @users.group_by { |user| user.generation }
    @grouped_by_type = @users.group_by { |user| user.user_type }
  end
end 