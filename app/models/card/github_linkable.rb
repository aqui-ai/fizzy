module Card::GithubLinkable
  extend ActiveSupport::Concern

  REFERENCE_FORMAT = /\A([A-Z][A-Z0-9]+)-(\d+)\z/

  included do
    has_one :github_issue, class_name: "Github::Issue", dependent: :nullify
    has_many :github_pull_requests, class_name: "Github::PullRequest", dependent: :nullify

    scope :with_github_issue, -> { where(id: Github::Issue.where.not(card_id: nil).select(:card_id)) }
    scope :with_github_pull_request, -> { where(id: Github::PullRequest.where.not(card_id: nil).select(:card_id)) }
  end

  class_methods do
    # Resolves a "KEY-NUMBER" token to a card, requiring the board key to match
    # so a mistyped key never links to the wrong card.
    def find_by_reference(reference, account: Current.account)
      if match = reference.to_s.match(REFERENCE_FORMAT)
        account.cards.joins(:board).find_by(number: match[2], boards: { key: match[1] })
      end
    end
  end

  def github_linked?
    github_issue.present? || github_pull_requests.any?
  end

  def reference
    "#{board.key}-#{number}"
  end

  # Card-stable (no per-user handle) so it is safe to render inside the fragment
  # cache. The KEY-NUMBER token is what links the branch back to this card.
  def git_branch_name
    [ board.key.downcase, number, title.to_s.parameterize.presence ].compact.join("-")
  end
end
