require "test_helper"

class Account::IntegrationEvents::RetriesControllerTest < ActionDispatch::IntegrationTest
  test "admins re-enqueue a failed event" do
    sign_in_as :kevin
    event = accounts("37s").integration_events.create!(provider: "github", event_type: "issues", payload: {}, status: :failed)

    assert_enqueued_with(job: Integrations::ProcessEventJob) do
      post account_integration_event_retry_path(event)
    end

    assert_predicate event.reload, :pending?
    assert_redirected_to account_integration_events_path
  end

  test "members are forbidden" do
    sign_in_as :david
    event = accounts("37s").integration_events.create!(provider: "github", event_type: "issues", status: :failed)

    post account_integration_event_retry_path(event)

    assert_response :forbidden
  end
end
