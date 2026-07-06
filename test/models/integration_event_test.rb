require "test_helper"

class IntegrationEventTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
  end

  test "ingest is idempotent per provider and external id" do
    first = @account.integration_events.ingest(provider: "github", event_type: "issues", payload: {}, external_id: "d1")
    duplicate = @account.integration_events.ingest(provider: "github", event_type: "issues", payload: {}, external_id: "d1")

    assert_not_nil first
    assert_nil duplicate
  end

  test "process_now marks unhandled events as ignored" do
    event = @account.integration_events.create!(provider: "github", event_type: "label", payload: {}, status: :pending)

    event.process_now

    assert_predicate event, :ignored?
  end

  test "process_now runs handled github events and marks them processed" do
    repository = @account.github_repositories.create!(github_id: 100, full_name: "a/b", name: "b", board: boards(:writebook))
    payload = { "action" => "opened", "issue" => { "id" => 1, "number" => 5, "title" => "T", "state" => "open", "labels" => [], "assignees" => [] }, "repository" => { "id" => 100 } }
    event = @account.integration_events.create!(provider: "github", event_type: "issues", payload: payload, status: :pending)

    event.process_now

    assert_predicate event, :processed?
    assert_not_nil repository.issues.find_by(number: 5)
  end

  test "process_now records failures with a message" do
    @account.github_repositories.create!(github_id: 100, full_name: "a/b", name: "b", board: boards(:writebook))
    payload = { "action" => "opened", "issue" => {}, "repository" => { "id" => 100 } } # no issue number -> raises
    event = @account.integration_events.create!(provider: "github", event_type: "issues", payload: payload, status: :pending)

    event.process_now

    assert_predicate event, :failed?
    assert event.error_message.present?
  end
end
