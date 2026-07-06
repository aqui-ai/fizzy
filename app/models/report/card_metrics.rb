class Report::CardMetrics
  def initialize(cards:, window:)
    @cards = cards
    @window = window
  end

  def open
    active.count
  end

  def done
    @cards.closed.count
  end

  def not_now
    @cards.postponed.count
  end

  def overdue
    active.overdue.count
  end

  def due_this_week
    active.due_soon.count
  end

  def unassigned
    active.unassigned.count
  end

  def created_in_window
    @cards.where(cards: { created_at: @window }).count
  end

  def closed_in_window
    @cards.closed_at_window(@window).count
  end

  private
    def active
      @active ||= @cards.active
    end
end
