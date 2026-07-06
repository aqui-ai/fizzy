class Mcp::Tools::SubmitDailyUpdate < Mcp::Tool
  def self.scope
    :write
  end

  def self.description
    "Submit today's daily update for the authenticated user."
  end

  def self.input_schema
    {
      type: "object",
      properties: {
        completed: { type: "string", description: "What you completed yesterday" },
        planned: { type: "string", description: "What you are working on today" },
        blockers: { type: "string", description: "What is blocked" }
      }
    }
  end

  def call
    update = DailyUpdate.for_user(Current.user)
    update.assign_attributes(completed_yesterday: arg(:completed), planned_today: arg(:planned), blockers: arg(:blockers))
    update.submit
    { status: update.status, work_on: update.work_on.to_s }
  end
end
