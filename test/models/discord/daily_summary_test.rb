require "test_helper"

class Discord::DailySummaryTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @account.integrations.create!(provider: "discord", credentials: { "webhook_url" => "https://discord.com/api/webhooks/1/token" })
  end

  test "posts a summary listing missing daily updates" do
    @account.daily_updates.create!(user: users(:david), work_on: Date.current, status: :missing)
    stub_request(:post, "https://discord.com/api/webhooks/1/token").to_return(status: 204)

    Discord::DailySummary.new(@account).post

    assert_requested :post, "https://discord.com/api/webhooks/1/token" do |request|
      request.body.include?("David")
    end
  end

  test "does nothing when discord is not enabled" do
    @account.integrations.find_by(provider: "discord").update!(enabled: false)

    assert_nothing_raised { Discord::DailySummary.new(@account).post }
    assert_not_requested :post, "https://discord.com/api/webhooks/1/token"
  end

  test "post_all skips accounts on non-work days when weekends are excluded" do
    @account.update!(daily_update_exclude_weekends: true)

    travel_to Time.zone.local(2026, 7, 4, 12, 0) do # Saturday
      assert_nothing_raised { Discord::DailySummary.post_all }
    end
  end
end
