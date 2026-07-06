require "test_helper"

class Integrations::Github::WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts("37s")
    @account.create_github_configuration!(webhook_secret: "s3cr3t")
  end

  test "accepts a validly signed webhook and enqueues processing" do
    body = { action: "opened", issue: { number: 1 } }.to_json

    assert_enqueued_with(job: Github::ProcessWebhookJob) do
      post integrations_github_webhook_path, params: body, headers: signed_headers(body, "issues")
    end

    assert_response :accepted
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
    def signed_headers(body, event)
      {
        "X-Hub-Signature-256" => "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", "s3cr3t", body),
        "X-GitHub-Event" => event,
        "X-GitHub-Delivery" => "delivery-1",
        "Content-Type" => "application/json"
      }
    end
end
