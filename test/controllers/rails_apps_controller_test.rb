require "test_helper"

class RailsAppsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get rails_apps_create_url
    assert_response :success
  end
end
