class Mcp::Tool
  class << self
    def tool_name
      name.demodulize.underscore
    end

    def scope
      :read
    end

    def description
      ""
    end

    def input_schema
      { type: "object", properties: {} }
    end

    def definition
      { name: tool_name, description: description, inputSchema: input_schema }
    end

    def call(arguments)
      new(arguments).call
    end
  end

  def initialize(arguments = {})
    @arguments = arguments || {}
  end

  def call
    raise NotImplementedError
  end

  private
    def arg(key)
      @arguments[key.to_s]
    end

    def find_card!(number)
      Current.user.accessible_cards.published.find_by(number: number) || raise("Card ##{number} not found")
    end

    def card_summary(card)
      {
        number: card.number,
        title: card.title,
        board: card.board.name,
        priority: card.priority,
        due_on: card.due_on&.to_s,
        state: card_state(card)
      }
    end

    def card_state(card)
      return "closed" if card.closed?
      return "not_now" if card.postponed?
      "open"
    end
end
