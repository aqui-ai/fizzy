require "test_helper"

class IntegrationTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
  end

  test "provider is unique per account" do
    @account.integrations.create!(provider: "github")

    assert_not @account.integrations.build(provider: "github").valid?
  end

  test "reads settings and credentials by key" do
    integration = @account.integrations.create!(provider: "discord", settings: { "channel" => "ops" }, credentials: { "token" => "abc" })

    assert_equal "ops", integration.setting(:channel)
    assert_equal "abc", integration.credential(:token)
  end

  test "credentials are encrypted at rest" do
    integration = @account.integrations.create!(provider: "github", credentials: { "webhook_secret" => "topsecret" })

    raw = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql([ "SELECT credentials FROM integrations WHERE id = ?", integration.id ])
    )
    assert_not_includes raw.to_s, "topsecret"
    assert_equal "topsecret", Integration.find(integration.id).credential("webhook_secret")
  end
end
