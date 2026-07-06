class Kpi::DailyUserScore
  Reason = Data.define(:label, :points)

  MAX_COMPLETION = 30
  POINTS_PER_CLOSED_CARD = 10
  DEADLINE_POINTS = 20
  ACTIVITY_POINTS = 10

  def initialize(user:, date: Date.current)
    @user = user
    @date = date
  end

  def total
    reasons.sum(&:points)
  end

  def reasons
    @reasons ||= [ compliance_reason, completion_reason, deadline_reason, activity_reason ]
  end

  private
    def compliance_reason
      case daily_update&.status
      when "submitted" then Reason.new("Daily update submitted on time", 40)
      when "late"      then Reason.new("Daily update submitted late", 25)
      else                  Reason.new("Daily update missing", 0)
      end
    end

    def completion_reason
      count = closed_today_count
      if count.positive?
        Reason.new("#{count} #{"card".pluralize(count)} closed today", [ count * POINTS_PER_CLOSED_CARD, MAX_COMPLETION ].min)
      else
        Reason.new("No cards closed today", 0)
      end
    end

    def deadline_reason
      count = overdue_count
      if count.zero?
        Reason.new("No overdue assigned cards", DEADLINE_POINTS)
      else
        Reason.new("#{count} overdue assigned #{"card".pluralize(count)}", 0)
      end
    end

    def activity_reason
      if active_today?
        Reason.new("Active today", ACTIVITY_POINTS)
      else
        Reason.new("No activity today", 0)
      end
    end

    def daily_update
      @daily_update ||= DailyUpdate.for_date(@date).find_by(user: @user)
    end

    def closed_today_count
      @user.assigned_cards.closed.where(closures: { created_at: @date.all_day }).count
    end

    def overdue_count
      @user.assigned_cards.active.overdue.count
    end

    def active_today?
      Event.where(creator: @user, created_at: @date.all_day).exists?
    end
end
