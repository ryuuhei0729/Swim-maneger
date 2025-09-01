class LandingController < ApplicationController
  skip_before_action :authenticate_api_user!

  def index
    # ログインチェックを削除し、常にランディングページを表示
  end
end
