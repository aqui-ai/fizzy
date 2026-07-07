class Github::PullRequestSync
  Link = Data.define(:card, :automate)

  def initialize(payload)
    @action = payload["action"]
    @pr = payload["pull_request"] || {}
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    @link = resolve_link
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
          card: pull_request.card || @link&.card,
          last_synced_at: Time.current
        )
      end
    end

    def apply(pull_request)
      card = pull_request.card
      return unless card && automate?

      case @action
      when "opened", "reopened"
        advance card, draft? ? in_progress_column(card) : in_review_column(card)
      when "ready_for_review"
        advance card, in_review_column(card)
      when "converted_to_draft"
        advance card, in_progress_column(card)
      when "closed"
        complete card if pull_request.merged? && targets_default_branch?
      end
    end

    def automate?
      @link&.automate
    end

    def advance(card, column)
      return if column.nil? || card.closed? || card.column_id == column.id
      card.triage_into column
    end

    def complete(card)
      card.close unless card.closed?
    end

    # Prefer a card referenced by a KEY-NUMBER token; fall back to the legacy
    # GitHub issue number ("#42") so issue-mirrored repos keep working.
    def resolve_link
      link_from_references || legacy_issue_link
    end

    def link_from_references
      links = Github::References.extract(reference_text).filter_map do |reference|
        if card = Card.find_by_reference(reference.token)
          Link.new(card, reference.automate)
        end
      end

      links.find(&:automate) || links.first
    end

    def legacy_issue_link
      if number = reference_text[/#(\d+)/, 1]
        card = repository.issues.find_by(number: number)&.card
        Link.new(card, true) if card
      end
    end

    def reference_text
      [ @pr["title"], @pr["body"], @pr.dig("head", "ref") ].compact.join("\n")
    end

    def draft?
      @pr["draft"]
    end

    def targets_default_branch?
      default_branch = @pr.dig("base", "repo", "default_branch").presence
      default_branch.blank? || @pr.dig("base", "ref") == default_branch
    end

    def in_review_column(card)
      column_for card, "in_review_column_name", "In Review"
    end

    def in_progress_column(card)
      column_for card, "in_progress_column_name", "In Progress"
    end

    def column_for(card, setting_key, default_name)
      name = Current.account.github_integration.setting(setting_key).presence || default_name
      card.board.columns.find_by(name: name)
    end
end
