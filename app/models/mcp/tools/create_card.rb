class Mcp::Tools::CreateCard < Mcp::Tool
  def self.scope
    :write
  end

  def self.description
    "Create a published card on a board the user can access."
  end

  def self.input_schema
    {
      type: "object",
      required: %w[ board title ],
      properties: {
        board: { type: "string", description: "Board name or id" },
        title: { type: "string", description: "Card title" },
        description: { type: "string", description: "Card description (optional)" }
      }
    }
  end

  def call
    card = board.cards.create!(title: arg(:title), description: arg(:description), creator: Current.user, status: "published")
    { number: card.number, title: card.title, board: board.name }
  end

  private
    def board
      @board ||= Current.user.boards.find_by(name: arg(:board)) ||
                 Current.user.boards.find_by(id: arg(:board)) ||
                 raise("Board not found: #{arg(:board)}")
    end
end
