module Card::Prioritizable
  extend ActiveSupport::Concern

  PRIORITIES = %w[ none low medium high urgent ].freeze
  PRIORITY_LABELS = {
    "none" => "No priority",
    "low" => "Low",
    "medium" => "Medium",
    "high" => "High",
    "urgent" => "Urgent"
  }.freeze

  included do
    validates :priority, inclusion: { in: PRIORITIES }

    scope :prioritized, -> { where.not(priority: "none") }
    scope :priority, ->(priority) { where(priority:) }
  end

  class_methods do
    def priority_options
      PRIORITIES.map { |priority| [ PRIORITY_LABELS.fetch(priority), priority ] }
    end
  end

  def priority_label
    PRIORITY_LABELS.fetch(priority)
  end

  def prioritized?
    priority != "none"
  end
end
