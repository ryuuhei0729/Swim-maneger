class Api::V1::LandingController < Api::V1::BaseController
  skip_before_action :authenticate_user_auth!

  def index
    render_success({
      message: "水泳部管理システムAPI",
      login_required: true,
      login_endpoint: "/api/v1/auth/login"
    })
  end
end 