class Report::Snapshot < ApplicationRecord
  self.table_name = "report_snapshots"

  METRICS = %w[ open done not_now overdue due_this_week unassigned created closed ].freeze

  belongs_to :account

  scope :account_wide, -> { where(board_id: nil) }
  scope :chronologically, -> { order(:snapshot_on) }

  class << self
    def capture_all(on: Date.current)
      Account.find_each { |account| capture_for(account, on: on) }
    end

    def capture_for(account, on: Date.current)
      metrics = Report::CardMetrics.new(cards: account.cards.published, window: on.all_day)

      account.report_snapshots.find_or_initialize_by(board_id: nil, snapshot_on: on).update!(
        metrics: {
          "open" => metrics.open,
          "done" => metrics.done,
          "not_now" => metrics.not_now,
          "overdue" => metrics.overdue,
          "due_this_week" => metrics.due_this_week,
          "unassigned" => metrics.unassigned,
          "created" => metrics.created_in_window,
          "closed" => metrics.closed_in_window
        }
      )
    end
  end

  def metric(name)
    metrics.to_h.fetch(name.to_s, 0)
  end
end
