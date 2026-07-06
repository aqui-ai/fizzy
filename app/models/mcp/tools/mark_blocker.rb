class Mcp::Tools::MarkBlocker < Mcp::Tool
  def self.scope
    :write
  end

  def self.description
    "Mark a card as blocked (tags it 'blocked' and optionally records the reason as a comment)."
  end

  def self.input_schema
    {
      type: "object",
      required: %w[ card_number ],
      properties: {
        card_number: { type: "integer", description: "Card number" },
        reason: { type: "string", description: "Why it is blocked (optional)" }
      }
    }
  end

  def call
    card = find_card!(arg(:card_number))
    card.taggings.find_or_create_by!(tag: blocked_tag)
    card.comments.create!(body: arg(:reason), creator: Current.user) if arg(:reason).present?
    { card: card.number, blocked: true }
  end

  private
    def blocked_tag
      Current.account.tags.find_or_create_by!(title: "blocked")
    end
end
