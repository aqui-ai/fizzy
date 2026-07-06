class Github::PullRequestSync
  def initialize(payload)
    @action = payload["action"]
    @pr = payload["pull_request"] || {}
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    pull_request = upsert
    apply pull_request
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    def upsert
      repository.pull_requests.find_or_initialize_by(number: @pr["number"]).tap do |pull_request|
        pull_request.update!(
          github_id: @pr["id"],
          title: @pr["title"],
          html_url: @pr["html_url"],
          state: @pr["state"],
          merged: @pr["merged"] || false,
          merged_at: @pr["merged_at"],
          head_ref: @pr.dig("head", "ref"),
          board_id: repository.board_id,
          card: pull_request.card || linked_card,
          last_synced_at: Time.current
        )
      end
    end

    def apply(pull_request)
      case @action
      when "opened", "ready_for_review"
        move_to_review pull_request
      when "closed"
        pull_request.card&.close if pull_request.merged?
      end
    end

    def move_to_review(pull_request)
      card = pull_request.card
      return unless card

      column = card.board.columns.find_by(name: review_column_name)
      card.triage_into(column) if column && card.column_id != column.id
    end

    # Links to the card of the GitHub issue referenced in the PR (e.g. "Closes #42").
    def linked_card
      references = [ @pr["title"], @pr["body"], @pr.dig("head", "ref") ].compact.join(" ")
      if number = references[/#(\d+)/, 1]
        repository.issues.find_by(number: number)&.card
      end
    end

    def review_column_name
      Current.account.github_integration.setting("in_review_column_name").presence || "In Review"
    end
end
