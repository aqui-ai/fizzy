class Report::Github
  def initialize(account)
    @account = account
  end

  def open_cards_by_repository
    grouped issues.joins(:card, :repository).merge(Card.open)
  end

  def closed_cards_by_repository
    grouped issues.joins(:card, :repository).merge(Card.closed)
  end

  def open_pull_requests
    pull_requests.where(state: "open").count
  end

  def in_review
    pull_requests.where(state: "open").where.not(card_id: nil).count
  end

  def merged_this_week
    pull_requests.where(merged: true).where(merged_at: 1.week.ago..).count
  end

  def linked_repositories
    @account.github_repositories.where(id: issues.where.not(card_id: nil).select(:repository_id)).count
  end

  private
    def issues
      ::Github::Issue.where(account: @account)
    end

    def pull_requests
      ::Github::PullRequest.where(account: @account)
    end

    def grouped(relation)
      relation.group("github_repositories.full_name").count.sort_by { |_name, count| -count }.to_h
    end
end
