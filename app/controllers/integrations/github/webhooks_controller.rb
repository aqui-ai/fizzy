class Integrations::Github::WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  before_action :verify_signature

  def create
    event = Current.account.integration_events.ingest(
      provider: "github", event_type: event_name, external_id: delivery_id, payload: payload
    )
    Integrations::ProcessEventJob.perform_later(event) if event

    head :accepted
  end

  private
    def verify_signature
      head :unauthorized unless valid_signature?
    end

    def valid_signature?
      secret = Current.account&.github_integration&.credential("webhook_secret")
      return false if secret.blank?

      expected = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, request.raw_post)
      ActiveSupport::SecurityUtils.secure_compare(request.headers["X-Hub-Signature-256"].to_s, expected)
    end

    def payload
      JSON.parse(request.raw_post)
    rescue JSON::ParserError
      {}
    end

    def event_name
      request.headers["X-GitHub-Event"]
    end

    def delivery_id
      request.headers["X-GitHub-Delivery"]
    end
end
