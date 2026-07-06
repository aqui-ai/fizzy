require "test_helper"

class Account::Discord::IntegrationsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view and save the discord webhook" do
    sign_in_as :kevin

    get account_discord_integration_path
    assert_response :success

    patch account_discord_integration_path, params: { discord: { webhook_url: "https://discord.com/api/webhooks/1/token", enabled: "1" } }

    assert_redirected_to account_discord_integration_path
    integration = accounts("37s").integrations.find_by(provider: "discord")
    assert_equal "https://discord.com/api/webhooks/1/token", integration.credential("webhook_url")
    assert_predicate integration, :enabled?
  end

  test "members are forbidden" do
    sign_in_as :david
    get account_discord_integration_path
    assert_response :forbidden
  end
end
