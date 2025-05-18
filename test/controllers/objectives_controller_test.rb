require "test_helper"

class ObjectivesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get objectives_index_url
    assert_response :success
  end
end
