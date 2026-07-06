class Mcp::Tools::CommentOnCard < Mcp::Tool
  def self.scope
    :write
  end

  def self.description
    "Add a comment to a card by its number."
  end

  def self.input_schema
    {
      type: "object",
      required: %w[ card_number body ],
      properties: {
        card_number: { type: "integer", description: "Card number" },
        body: { type: "string", description: "Comment text" }
      }
    }
  end

  def call
    card = find_card!(arg(:card_number))
    comment = card.comments.create!(body: arg(:body), creator: Current.user)
    { card: card.number, comment_id: comment.id }
  end
end
