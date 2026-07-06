class Mcp::Tools::ListBlockers < Mcp::Tool
  def self.description
    "List accessible cards tagged as blocked."
  end

  def call
    blocked = Current.account.tags.find_by(title: "blocked")
    return [] unless blocked

    Current.user.accessible_cards.published.active.tagged_with(blocked).map { |card| card_summary(card) }
  end
end
