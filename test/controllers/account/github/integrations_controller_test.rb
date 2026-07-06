require "test_helper"

class Account::Github::IntegrationsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view GitHub settings" do
    sign_in_as :kevin
    get account_github_integration_path
    assert_response :success
  end

  test "members are forbidden" do
    sign_in_as :david
    get account_github_integration_path
    assert_response :forbidden
  end

  test "admins save the webhook configuration" do
    sign_in_as :kevin

    patch account_github_integration_path, params: { github_configuration: { webhook_secret: "s3cr3t", in_review_column_name: "Review" } }

    assert_redirected_to account_github_integration_path
    assert_equal "s3cr3t", accounts("37s").reload.github_configuration.webhook_secret
    assert_equal "Review", accounts("37s").github_configuration.in_review_column_name
  end

  test "a blank secret leaves the existing one untouched" do
    sign_in_as :kevin
    accounts("37s").create_github_configuration!(webhook_secret: "keepme")

    patch account_github_integration_path, params: { github_configuration: { webhook_secret: "", in_review_column_name: "QA" } }

    assert_equal "keepme", accounts("37s").reload.github_configuration.webhook_secret
    assert_equal "QA", accounts("37s").github_configuration.in_review_column_name
  end
end
