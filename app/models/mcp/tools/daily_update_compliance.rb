class Mcp::Tools::DailyUpdateCompliance < Mcp::Tool
  def self.description
    "Daily update compliance for a date (default today): each active user's status (submitted, late, missing or none)."
  end

  def self.input_schema
    { type: "object", properties: { date: { type: "string", description: "ISO date (optional, default today)" } } }
  end

  def call
    date = arg(:date).present? ? Date.parse(arg(:date)) : Date.current
    updates = Current.account.daily_updates.for_date(date).index_by(&:user_id)

    Current.account.users.active.order(:name).map do |user|
      { user: user.name, status: updates[user.id]&.status || "none" }
    end
  end
end
