require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @token = identities(:kevin).access_tokens.create!(permission: :read)
  end

  test "rejects requests without a valid token" do
    post mcp_path, params: {}.to_json, headers: json_headers
    assert_response :unauthorized
  end

  test "initialize returns server info" do
    body = rpc("initialize")

    assert_equal "2.0", body["jsonrpc"]
    assert_equal "fizzy", body.dig("result", "serverInfo", "name")
    assert_equal Mcp::PROTOCOL_VERSION, body.dig("result", "protocolVersion")
  end

  test "tools/list returns the read tools" do
    names = rpc("tools/list").dig("result", "tools").map { |tool| tool["name"] }

    assert_includes names, "list_boards"
    assert_includes names, "list_overdue"
    assert_includes names, "create_card"
  end

  test "tools/call runs a read tool" do
    body = rpc("tools/call", { name: "list_boards", arguments: {} })

    assert_match "Writebook", body.dig("result", "content", 0, "text")
  end

  test "tools/call reports unknown tools as an error" do
    body = rpc("tools/call", { name: "nope", arguments: {} })

    assert_equal(-32602, body.dig("error", "code"))
  end

  test "notifications get no response body" do
    post mcp_path, params: { jsonrpc: "2.0", method: "notifications/initialized" }.to_json, headers: auth_headers
    assert_response :accepted
  end

  private
    def rpc(method, params = {}, id: 1)
      post mcp_path, params: { jsonrpc: "2.0", id: id, method: method, params: params }.to_json, headers: auth_headers
      JSON.parse(@response.body)
    end

    def json_headers
      { "Content-Type" => "application/json", "Accept" => "application/json" }
    end

    def auth_headers
      json_headers.merge("Authorization" => "Bearer #{@token.token}")
    end
end
