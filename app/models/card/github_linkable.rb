module Card::GithubLinkable
  extend ActiveSupport::Concern

  included do
    has_one :github_issue, class_name: "Github::Issue", dependent: :nullify
    has_many :github_pull_requests, class_name: "Github::PullRequest", dependent: :nullify
  end

  def github_linked?
    github_issue.present? || github_pull_requests.any?
  end
end
