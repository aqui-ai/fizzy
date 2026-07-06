module Mcp
  PROTOCOL_VERSION = "2024-11-05"
  SERVER_NAME = "fizzy"
  VERSION = "1.0.0"

  class Error < StandardError
    attr_reader :code

    def initialize(code, message)
      @code = code
      super(message)
    end
  end
end
