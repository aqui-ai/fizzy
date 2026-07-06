require "test_helper"

class Reports::DailyPerformancesControllerTest < ActionDispatch::IntegrationTest
  test "admins can view the daily performance dashboard" do
    sign_in_as :kevin
    get reports_daily_performance_path
    assert_response :success
  end

  test "members without a team are forbidden" do
    sign_in_as :david
    get reports_daily_performance_path
    assert_response :forbidden
  end

  test "a team lead can view their team's performance" do
    company = accounts("37s").teams.create!(name: "AQUI")
    company.memberships.create!(user: users(:david), lead: true)
    company.memberships.create!(user: users(:jz))

    sign_in_as :david
    get reports_daily_performance_path

    assert_response :success
    assert_match "JZ", @response.body
  end
end
