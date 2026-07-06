require "test_helper"

class Account::IntegrationEventsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view integration events with error details" do
    sign_in_as :kevin
    accounts("37s").integration_events.create!(provider: "github", event_type: "issues", status: :failed, error_message: "boom")

    get account_integration_events_path

    assert_response :success
    assert_match "boom", @response.body
  end

  test "members are forbidden" do
    sign_in_as :david
    get account_integration_events_path
    assert_response :forbidden
  end
end
