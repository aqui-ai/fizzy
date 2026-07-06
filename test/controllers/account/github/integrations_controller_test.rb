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

    patch account_github_integration_path, params: { github: { webhook_secret: "s3cr3t", in_review_column_name: "Review" } }

    assert_redirected_to account_github_integration_path
    integration = accounts("37s").reload.github_integration
    assert_equal "s3cr3t", integration.credential("webhook_secret")
    assert_equal "Review", integration.setting("in_review_column_name")
  end

  test "a blank secret leaves the existing one untouched" do
    sign_in_as :kevin
    accounts("37s").integrations.create!(provider: "github", credentials: { "webhook_secret" => "keepme" })

    patch account_github_integration_path, params: { github: { webhook_secret: "", in_review_column_name: "QA" } }

    integration = accounts("37s").reload.github_integration
    assert_equal "keepme", integration.credential("webhook_secret")
    assert_equal "QA", integration.setting("in_review_column_name")
  end
end
