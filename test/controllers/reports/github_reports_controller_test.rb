require "test_helper"

class Reports::GithubReportsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view the engineering report" do
    sign_in_as :kevin
    get reports_github_report_path
    assert_response :success
  end

  test "members are forbidden" do
    sign_in_as :david
    get reports_github_report_path
    assert_response :forbidden
  end
end
