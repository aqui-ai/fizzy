class Github::Repository < ApplicationRecord
  belongs_to :account
  belongs_to :board, optional: true

  has_many :issues, dependent: :destroy
  has_many :pull_requests, dependent: :destroy

  scope :active, -> { where(active: true) }

  validates :github_id, uniqueness: { scope: :account_id }
  validates :full_name, uniqueness: { scope: :account_id }

  class << self
    # Records a repository from a webhook payload so it shows up in settings
    # for an admin to map to a board. Returns nil for a blank payload.
    def register(payload)
      return if payload["id"].blank?

      find_or_initialize_by(github_id: payload["id"]).tap do |repository|
        repository.update!(
          owner: payload.dig("owner", "login") || repository.owner,
          name: payload["name"] || repository.name,
          full_name: payload["full_name"].presence || repository.full_name || "repo-#{payload["id"]}",
          html_url: payload["html_url"] || repository.html_url
        )
      end
    end
  end

  def mapped?
    board_id.present?
  end

  def syncing?
    active? && mapped?
  end
end
