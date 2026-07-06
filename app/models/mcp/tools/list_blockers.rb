class Mcp::Tools::ListBlockers < Mcp::Tool
  def self.description
    "List accessible cards tagged as blocked."
  end

  def call
    Current.user.accessible_cards.published.active
      .joins(:tags).where(tags: { title: "blocked" }).distinct
      .map { |card| card_summary(card) }
  end
end
