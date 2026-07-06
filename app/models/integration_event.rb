class IntegrationEvent < ApplicationRecord
  belongs_to :account
  belongs_to :integration, optional: true

  enum :status, %w[ pending processed failed ignored ].index_by(&:itself)

  scope :recent, -> { order(created_at: :desc) }

  class << self
    # Idempotent: a repeated delivery (same provider + external_id) returns nil.
    def ingest(provider:, event_type:, payload:, external_id: nil, integration: nil)
      create!(
        provider: provider, event_type: event_type, payload: payload,
        external_id: external_id.presence, integration: integration,
        received_at: Time.current, status: :pending
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end

  def process_now
    return if processed?

    if Integrations::Router.dispatch(self)
      mark_processed!
    else
      mark_ignored!
    end
  rescue => error
    mark_failed!(error.message)
  end

  def mark_processed!
    update!(status: :processed, processed_at: Time.current, failed_at: nil, error_message: nil)
  end

  def mark_failed!(message)
    update!(status: :failed, failed_at: Time.current, error_message: message.to_s.truncate(1000))
  end

  def mark_ignored!
    update!(status: :ignored, processed_at: Time.current)
  end
end
