class Discord::DailySummary
  def self.post_all(as_of: Date.current)
    Account.find_each do |account|
      next unless account.daily_update_workday?(as_of)

      Current.with_account(account) { new(account, as_of).post }
    end
  end

  def initialize(account, as_of = Date.current)
    @account = account
    @as_of = as_of
  end

  def post
    notifier = Discord::Notifier.new(@account)
    notifier.notify(message) if notifier.configured?
  end

  private
    def message
      [ "**Daily standup — #{@as_of.strftime("%A, %b %-d")}**", missing_line, overdue_line ].join("\n")
    end

    def missing_line
      names = @account.daily_updates.for_date(@as_of).missing.includes(:user).map { |update| update.user.name }
      names.any? ? "⚠️ Missing daily update: #{names.join(", ")}" : "✅ Everyone submitted their daily update"
    end

    def overdue_line
      count = @account.cards.published.active.overdue.count
      "📌 Overdue cards: #{count}"
    end
end
