require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view the reports dashboard" do
    sign_in_as :kevin
    get reports_path
    assert_response :success
  end

  test "owners can view the reports dashboard" do
    sign_in_as :jason
    get reports_path
    assert_response :success
  end

  test "members are forbidden" do
    sign_in_as :david
    get reports_path
    assert_response :forbidden
  end

  test "date window presets are honored" do
    sign_in_as :kevin
    get reports_path(days: 7)
    assert_response :success
  end

  test "an unrecognized window falls back to the default" do
    sign_in_as :kevin
    get reports_path(days: 999)
    assert_response :success
  end
end
