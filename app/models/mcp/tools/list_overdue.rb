class Mcp::Tools::ListOverdue < Mcp::Tool
  def self.description
    "List accessible cards that are past their deadline."
  end

  def call
    Current.user.accessible_cards.published.active.overdue.map { |card| card_summary(card) }
  end
end
