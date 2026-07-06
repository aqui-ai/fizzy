class Report::Aging
  def initialize(cards:)
    @cards = cards
  end

  def average_open_age_in_days
    created_ats = @cards.active.pluck(:created_at)
    average_days created_ats.map { |created_at| Time.current - created_at }
  end

  def average_time_to_close_in_days
    closed_cards = @cards.closed.includes(:closure)
    average_days closed_cards.map { |card| card.closed_at - card.created_at }
  end

  private
    def average_days(seconds)
      return 0 if seconds.empty?
      (seconds.sum / seconds.size / 1.day).round
    end
end
