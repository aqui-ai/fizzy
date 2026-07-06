require "test_helper"

class Reports::DailyPerformancesControllerTest < ActionDispatch::IntegrationTest
  test "admins can view the daily performance dashboard" do
    sign_in_as :kevin
    get reports_daily_performance_path
    assert_response :success
  end

  test "members are forbidden" do
    sign_in_as :david
    get reports_daily_performance_path
    assert_response :forbidden
  end
end
