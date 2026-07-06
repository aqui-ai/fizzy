class Mcp::Server
  def initialize(access_token:)
    @access_token = access_token
  end

  def handle(request)
    id = request["id"]

    case request["method"]
    when "initialize"                 then success(id, initialize_result)
    when "tools/list"                 then success(id, { tools: Mcp::Registry.all.map(&:definition) })
    when "tools/call"                 then success(id, call_tool(request["params"] || {}))
    when "ping"                       then success(id, {})
    when %r{\Anotifications/}         then nil # notifications get no response
    else error(id, -32601, "Method not found: #{request["method"]}")
    end
  rescue Mcp::Error => e
    error(id, e.code, e.message)
  end

  private
    def initialize_result
      {
        protocolVersion: Mcp::PROTOCOL_VERSION,
        capabilities: { tools: {} },
        serverInfo: { name: Mcp::SERVER_NAME, version: Mcp::VERSION }
      }
    end

    def call_tool(params)
      tool = Mcp::Registry.find(params["name"])
      raise Mcp::Error.new(-32602, "Unknown tool: #{params["name"]}") unless tool

      if tool.scope == :write && !@access_token.write?
        raise Mcp::Error.new(-32001, "This access token is read-only")
      end

      text_content tool.call(params["arguments"])
    rescue Mcp::Error
      raise
    rescue => e
      { content: [ { type: "text", text: "Error: #{e.message}" } ], isError: true }
    end

    def text_content(output)
      text = output.is_a?(String) ? output : JSON.pretty_generate(output)
      { content: [ { type: "text", text: text } ] }
    end

    def success(id, result)
      { jsonrpc: "2.0", id: id, result: result } if id
    end

    def error(id, code, message)
      { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
    end
end
