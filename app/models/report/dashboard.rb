class Report::Dashboard
  attr_reader :cards, :window

  def initialize(cards:, window:)
    @cards = cards
    @window = window
  end

  def card_metrics
    @card_metrics ||= Report::CardMetrics.new(cards: cards, window: window)
  end

  def throughput
    @throughput ||= Report::Throughput.new(cards: cards, window: window)
  end

  def aging
    @aging ||= Report::Aging.new(cards: cards)
  end
end
