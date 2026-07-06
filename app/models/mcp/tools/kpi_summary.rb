class Mcp::Tools::KpiSummary < Mcp::Tool
  def self.description
    "KPI score per active user for a date (default today), each with its explaining reasons."
  end

  def self.input_schema
    { type: "object", properties: { date: { type: "string", description: "ISO date (optional, default today)" } } }
  end

  def call
    date = arg(:date).present? ? Date.parse(arg(:date)) : Date.current

    Current.account.users.active.order(:name).map do |user|
      score = Kpi::DailyUserScore.new(user: user, date: date)
      { user: user.name, score: score.total, reasons: score.reasons.map { |reason| "#{reason.label} (+#{reason.points})" } }
    end
  end
end
