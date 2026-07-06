class Integrations::Github::WebhooksController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  before_action :verify_signature

  def create
    Github::ProcessWebhookJob.perform_later(event: event_name, delivery: delivery_id, payload: payload)
    head :accepted
  end

  private
    def verify_signature
      head :unauthorized unless valid_signature?
    end

    def valid_signature?
      secret = Current.account&.github_configuration&.webhook_secret
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
