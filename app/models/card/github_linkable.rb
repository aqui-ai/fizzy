module Card::GithubLinkable
  extend ActiveSupport::Concern

  included do
    has_one :github_issue, class_name: "Github::Issue", dependent: :nullify
    has_many :github_pull_requests, class_name: "Github::PullRequest", dependent: :nullify

    scope :with_github_issue, -> { where(id: Github::Issue.where.not(card_id: nil).select(:card_id)) }
    scope :with_github_pull_request, -> { where(id: Github::PullRequest.where.not(card_id: nil).select(:card_id)) }
  end

  def github_linked?
    github_issue.present? || github_pull_requests.any?
  end
end
