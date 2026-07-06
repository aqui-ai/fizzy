require "net/http"

class Discord::Notifier
  def initialize(account)
    @integration = account.integrations.find_by(provider: "discord")
  end

  def configured?
    @integration&.enabled? && webhook_url.present?
  end

  def notify(content)
    return false unless configured?

    deliver(content)
  end

  private
    def webhook_url
      @integration&.credential("webhook_url")
    end

    def deliver(content)
      uri = URI(webhook_url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = { content: content }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") { |http| http.request(request) }
      response.is_a?(Net::HTTPSuccess)
    end
end
