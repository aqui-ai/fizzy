class Report::Throughput
  def initialize(cards:, window:)
    @cards = cards
    @window = window
  end

  def by_board
    sorted closed_in_window.joins(:board).group("boards.name").count
  end

  def by_assignee
    sorted closed_in_window.joins(:assignees).group("users.name").count
  end

  private
    def closed_in_window
      @closed_in_window ||= @cards.closed_at_window(@window)
    end

    def sorted(counts)
      counts.sort_by { |_name, count| -count }.to_h
    end
end
