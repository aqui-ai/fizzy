require "test_helper"

class Github::AppTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    @key = OpenSSL::PKey::RSA.new(2048)
    @integration = @account.integrations.create!(provider: "github", credentials: {
      "app_id" => "123456",
      "app_installation_id" => "999",
      "app_private_key" => @key.to_pem
    })
    @app = Github::App.new(@integration)
  end

  test "configured? requires app id, key and installation id" do
    assert_predicate @app, :configured?
    assert_not Github::App.new(@account.integrations.build(provider: "x", credentials: {})).configured?
  end

  test "jwt is signed with the private key and carries the app id as issuer" do
    payload, header = JWT.decode(@app.jwt, @key.public_key, true, algorithm: "RS256")

    assert_equal "RS256", header["alg"]
    assert_equal "123456", payload["iss"]
    assert_operator payload["exp"], :>, payload["iat"]
  end

  test "installation_token exchanges the jwt for an installation token" do
    stub_request(:post, "https://api.github.com/app/installations/999/access_tokens")
      .to_return(status: 201, body: { token: "ghs_installation" }.to_json, headers: { "Content-Type" => "application/json" })

    assert_equal "ghs_installation", @app.installation_token
  end

  test "installation_token is nil when not configured" do
    assert_nil Github::App.new(@account.integrations.build(provider: "x", credentials: {})).installation_token
  end
end
