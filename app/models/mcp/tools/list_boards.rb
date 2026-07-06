class Mcp::Tools::ListBoards < Mcp::Tool
  def self.description
    "List the boards the authenticated user can access."
  end

  def call
    Current.user.boards.order(:name).map { |board| { id: board.id, name: board.name } }
  end
end
