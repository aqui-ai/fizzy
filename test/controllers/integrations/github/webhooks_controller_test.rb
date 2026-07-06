require "test_helper"

class Integrations::Github::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts("37s")
    @account.create_github_configuration!(webhook_secret: "s3cr3t")
  end

  test "accepts a validly signed webhook, persists an event and enqueues processing" do
    body = { action: "opened", issue: { number: 1 } }.to_json

    assert_difference -> { @account.integration_events.count }, +1 do
      assert_enqueued_with(job: Integrations::ProcessEventJob) do
        post integrations_github_webhook_path, params: body, headers: signed_headers(body, "issues")
      end
    end

    assert_response :accepted
  end

  test "deduplicates repeated deliveries by delivery id" do
    body = { action: "opened", issue: { number: 1 } }.to_json
    headers = signed_headers(body, "issues")

    post integrations_github_webhook_path, params: body, headers: headers

    assert_no_difference -> { @account.integration_events.count } do
      post integrations_github_webhook_path, params: body, headers: headers
    end
    assert_response :accepted
  end

  test "processing a webhook creates the linked card" do
    repository = @account.github_repositories.create!(github_id: 424_242, full_name: "a/b", name: "b", board: boards(:writebook))
    body = { action: "opened", issue: { id: 1, number: 5, title: "Hi", state: "open", labels: [], assignees: [] }, repository: { id: 424_242 } }.to_json

    perform_enqueued_jobs do
      post integrations_github_webhook_path, params: body, headers: signed_headers(body, "issues", delivery: "dX")
    end

    assert_not_nil repository.issues.find_by(number: 5)&.card
    assert_predicate @account.integration_events.find_by(external_id: "dX"), :processed?
  end

  test "rejects an invalid signature" do
    body = "{}"

    post integrations_github_webhook_path, params: body,
      headers: { "X-Hub-Signature-256" => "sha256=deadbeef", "X-GitHub-Event" => "issues", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "rejects when no webhook secret is configured" do
    @account.github_configuration.destroy!
    body = "{}"

    post integrations_github_webhook_path, params: body, headers: signed_headers(body, "issues")

    assert_response :unauthorized
  end

  private
    def signed_headers(body, event, delivery: "delivery-1")
      {
        "X-Hub-Signature-256" => "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "s3cr3t", body),
        "X-GitHub-Event" => event,
        "X-GitHub-Delivery" => delivery,
        "Content-Type" => "application/json"
      }
    end
end
