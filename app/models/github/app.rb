require "jwt"
require "net/http"

# Authenticates as a GitHub App installation: signs a short-lived JWT with the
# app's private key and exchanges it for an installation access token (cached
# just under GitHub's one-hour expiry). Preferred over a personal access token.
class Github::App
  TOKEN_TTL = 50.minutes
  JWT_TTL = 9.minutes

  def initialize(integration)
    @integration = integration
  end

  def configured?
    app_id.present? && private_key.present? && installation_id.present?
  end

  def installation_token
    return unless configured?

    Rails.cache.fetch(cache_key, expires_in: TOKEN_TTL) { request_installation_token }
  end

  def jwt
    now = Time.now.to_i
    payload = { iat: now - 60, exp: now + JWT_TTL.to_i, iss: app_id }
    JWT.encode(payload, OpenSSL::PKey::RSA.new(private_key), "RS256")
  end

  private
    def app_id
      @integration.credential("app_id")
    end

    def private_key
      @integration.credential("app_private_key")
    end

    def installation_id
      @integration.credential("app_installation_id")
    end

    def request_installation_token
      uri = URI("#{Github::Client::BASE_URL}/app/installations/#{installation_id}/access_tokens")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{jwt}"
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = "Fizzy"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
      JSON.parse(response.body)["token"] if response.is_a?(Net::HTTPSuccess)
    end

    def cache_key
      "github/installation_token/#{@integration.id}"
    end
end
