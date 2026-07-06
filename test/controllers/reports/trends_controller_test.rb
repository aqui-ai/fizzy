require "test_helper"

class Reports::TrendsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view trends" do
    sign_in_as :kevin
    Report::Snapshot.capture_for(accounts("37s"))

    get reports_trend_path
    assert_response :success
  end

  test "trends render before any snapshots exist" do
    sign_in_as :kevin
    get reports_trend_path
    assert_response :success
  end

  test "members are forbidden" do
    sign_in_as :david
    get reports_trend_path
    assert_response :forbidden
  end
end
