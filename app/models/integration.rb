class Integration < ApplicationRecord
  serialize :credentials, coder: JSON, type: Hash
  encrypts :credentials

  belongs_to :account
  has_many :integration_events, dependent: :nullify

  validates :provider, uniqueness: { scope: :account_id }

  scope :enabled, -> { where(enabled: true) }

  def setting(key)
    settings&.dig(key.to_s)
  end

  def credential(key)
    credentials&.dig(key.to_s)
  end
end
