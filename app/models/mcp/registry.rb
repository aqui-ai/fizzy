module Mcp::Registry
  def self.all
    [
      Mcp::Tools::ListBoards,
      Mcp::Tools::ListCards,
      Mcp::Tools::ListOverdue,
      Mcp::Tools::ListBlockers,
      Mcp::Tools::DailyUpdateCompliance,
      Mcp::Tools::KpiSummary,
      Mcp::Tools::CreateCard,
      Mcp::Tools::CommentOnCard,
      Mcp::Tools::AssignCard,
      Mcp::Tools::SubmitDailyUpdate,
      Mcp::Tools::MarkBlocker
    ]
  end

  def self.find(name)
    all.find { |tool| tool.tool_name == name }
  end
end
