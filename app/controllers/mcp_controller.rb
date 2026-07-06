class McpController < ApplicationController
  allow_unauthenticated_access
  skip_forgery_protection

  before_action :authenticate_access_token

  def handle
    server = Mcp::Server.new(access_token: @access_token)
    payload = parse_payload

    if payload.is_a?(Array)
      responses = payload.filter_map { |request| server.handle(request) }
      responses.any? ? render(json: responses) : head(:accepted)
    else
      response = server.handle(payload)
      response ? render(json: response) : head(:accepted)
    end
  rescue JSON::ParserError
    render json: { jsonrpc: "2.0", id: nil, error: { code: -32_700, message: "Parse error" } }, status: :bad_request
  end

  private
    def authenticate_access_token
      @access_token = Identity::AccessToken.find_by(token: bearer_token) if bearer_token
      Current.identity = @access_token.identity if @access_token

      head :unauthorized unless @access_token && Current.account && Current.user
    end

    def bearer_token
      request.authorization.to_s[/\ABearer\s+(.+)\z/, 1]
    end

    def parse_payload
      JSON.parse(request.raw_post)
    end
end
