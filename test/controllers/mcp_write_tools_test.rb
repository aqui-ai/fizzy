require "test_helper"

class McpWriteToolsTest < ActionDispatch::IntegrationTest
  setup do
    @write_token = identities(:kevin).access_tokens.create!(permission: :write)
    @read_token = identities(:kevin).access_tokens.create!(permission: :read)
  end

  test "read-only tokens cannot call write tools" do
    body = call_tool("create_card", { board: "Writebook", title: "X" }, token: @read_token)

    assert_equal(-32001, body.dig("error", "code"))
  end

  test "create_card creates a published card" do
    assert_difference -> { boards(:writebook).cards.count }, +1 do
      call_tool("create_card", { board: "Writebook", title: "From MCP" }, token: @write_token)
    end

    assert_equal "From MCP", boards(:writebook).cards.order(:created_at).last.title
  end

  test "comment_on_card adds a comment attributed to the token user" do
    body = call_tool("comment_on_card", { card_number: cards(:logo).number, body: "Looks good" }, token: @write_token)

    assert body.dig("result", "content", 0, "text").present?
    assert_equal users(:kevin), cards(:logo).comments.order(:created_at).last.creator
  end

  test "assign_card assigns the card to the token user" do
    call_tool("assign_card", { card_number: cards(:logo).number }, token: @write_token)

    assert cards(:logo).assigned_to?(users(:kevin))
  end

  test "mark_blocker tags the card blocked" do
    call_tool("mark_blocker", { card_number: cards(:logo).number, reason: "waiting on API" }, token: @write_token)

    assert_includes cards(:logo).tags.pluck(:title), "blocked"
  end

  private
    def call_tool(name, arguments, token:)
      post mcp_path,
        params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: name, arguments: arguments } }.to_json,
        headers: { "Content-Type" => "application/json", "Accept" => "application/json", "Authorization" => "Bearer #{token.token}" }
      JSON.parse(@response.body)
    end
end
