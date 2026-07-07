require "test_helper"

class Integrations::Github::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts("37s")
    @account.integrations.create!(provider: "github", credentials: { "webhook_secret" => "s3cr3t" })
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
    repository = @account.github_repositories.create!(github_id: 424_242, full_name: "a/b", name: "b", board: boards(:writebook), sync_issues: true)
    body = { action: "opened", issue: { id: 1, number: 5, title: "Hi", state: "open", labels: [], assignees: [] }, repository: { id: 424_242 } }.to_json

    perform_enqueued_jobs do
      post integrations_github_webhook_path, params: body, headers: signed_headers(body, "issues", delivery: "dX")
    end

    assert_not_nil repository.issues.find_by(number: 5)&.card
    assert_predicate @account.integration_events.find_by(external_id: "dX"), :processed?
  end

  test "processing a PR webhook links a native card by branch name and moves it to review" do
    Current.account = @account
    Current.user = @account.system_user
    @account.github_integration.update!(settings: { "in_review_column_name" => "Review" })
    @account.github_repositories.create!(github_id: 424_242, full_name: "a/b", name: "b", board: boards(:writebook))
    card = boards(:writebook).cards.create!(title: "Native", creator: @account.system_user, status: "published")

    body = {
      action: "ready_for_review",
      pull_request: { id: 9, number: 9, title: "Some work", state: "open", merged: false, draft: false,
                      html_url: "https://github.com/a/b/pull/9", head: { ref: card.git_branch_name }, base: { ref: "main" } },
      repository: { id: 424_242 }
    }.to_json

    perform_enqueued_jobs do
      post integrations_github_webhook_path, params: body, headers: signed_headers(body, "pull_request", delivery: "pr9")
    end

    assert_equal card, @account.github_repositories.first.pull_requests.find_by(number: 9).card
    assert_equal columns(:writebook_review), card.reload.column
    assert_predicate @account.integration_events.find_by(external_id: "pr9"), :processed?
  end

  test "rejects an invalid signature" do
    body = "{}"

    post integrations_github_webhook_path, params: body,
      headers: { "X-Hub-Signature-256" => "sha256=deadbeef", "X-GitHub-Event" => "issues", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "rejects when no webhook secret is configured" do
    @account.github_integration.destroy!
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
