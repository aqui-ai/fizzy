class Github::IssueSync
  def initialize(payload)
    @action = payload["action"]
    @issue = payload["issue"] || {}
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    issue = upsert
    apply issue
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    def upsert
      repository.issues.find_or_initialize_by(number: @issue["number"]).tap do |issue|
        issue.update!(
          github_id: @issue["id"],
          title: @issue["title"],
          body: @issue["body"],
          html_url: @issue["html_url"],
          state: @issue["state"],
          labels: names(@issue["labels"], "name"),
          assignees: names(@issue["assignees"], "login"),
          opened_at: @issue["created_at"],
          closed_at: @issue["closed_at"],
          board_id: repository.board_id,
          last_synced_at: Time.current
        )
      end
    end

    def apply(issue)
      case @action
      when "opened"
        link_card issue
      when "reopened"
        link_card issue
        issue.card&.reopen
      when "closed"
        issue.card&.close
      when "edited", "assigned", "unassigned", "labeled", "unlabeled"
        sync_title issue
      end
    end

    def link_card(issue)
      if issue.card.nil? && repository.syncing?
        card = repository.board.cards.create!(title: card_title(issue), creator: Current.user, status: "published")
        issue.update!(card: card)
      end
    end

    def sync_title(issue)
      issue.card.update!(title: issue.title) if issue.card && issue.title.present?
    end

    def card_title(issue)
      issue.title.presence || "Issue ##{issue.number}"
    end

    def names(list, key)
      Array(list).filter_map { |item| item[key] }
    end
end
