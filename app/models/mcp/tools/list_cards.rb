class Mcp::Tools::ListCards < Mcp::Tool
  def self.description
    "List accessible cards, optionally filtered by board name and status."
  end

  def self.input_schema
    {
      type: "object",
      properties: {
        board: { type: "string", description: "Board name to filter by (optional)" },
        status: { type: "string", enum: %w[ open closed overdue unassigned ], description: "Status filter (optional)" },
        limit: { type: "integer", description: "Maximum number of cards (default 25)" }
      }
    }
  end

  def call
    scope = Current.user.accessible_cards.published
    scope = scope.where(board: Current.user.boards.where(name: arg(:board))) if arg(:board).present?
    scope = filter_by_status(scope)
    scope.reverse_chronologically.limit(arg(:limit) || 25).map { |card| card_summary(card) }
  end

  private
    def filter_by_status(scope)
      case arg(:status)
      when "open"       then scope.active
      when "closed"     then scope.closed
      when "overdue"    then scope.active.overdue
      when "unassigned" then scope.active.unassigned
      else scope
      end
    end
end
