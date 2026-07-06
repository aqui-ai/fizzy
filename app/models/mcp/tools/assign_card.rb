class Mcp::Tools::AssignCard < Mcp::Tool
  def self.scope
    :write
  end

  def self.description
    "Assign a card to a user by name; defaults to the authenticated user."
  end

  def self.input_schema
    {
      type: "object",
      required: %w[ card_number ],
      properties: {
        card_number: { type: "integer", description: "Card number" },
        assignee: { type: "string", description: "User name to assign (optional, defaults to you)" }
      }
    }
  end

  def call
    card = find_card!(arg(:card_number))
    card.toggle_assignment(assignee) unless card.assigned_to?(assignee)
    { card: card.number, assignee: assignee.name }
  end

  private
    def assignee
      @assignee ||=
        if arg(:assignee).present?
          Current.account.users.active.find_by(name: arg(:assignee)) || raise("User not found: #{arg(:assignee)}")
        else
          Current.user
        end
    end
end
