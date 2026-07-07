require "test_helper"

class Github::AuthTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
  end

  test "uses the personal access token when no app is configured" do
    integration = @account.integrations.create!(provider: "github", credentials: { "api_token" => "ghp_pat" })

    assert_equal "ghp_pat", Github::Auth.token(integration)
  end

  test "prefers the app installation token when configured" do
    key = OpenSSL::PKey::RSA.new(2048)
    integration = @account.integrations.create!(provider: "github", credentials: {
      "api_token" => "ghp_pat",
      "app_id" => "1", "app_installation_id" => "2", "app_private_key" => key.to_pem
    })
    stub_request(:post, "https://api.github.com/app/installations/2/access_tokens")
      .to_return(status: 201, body: { token: "ghs_app" }.to_json, headers: { "Content-Type" => "application/json" })

    assert_equal "ghs_app", Github::Auth.token(integration)
  end
end
