# Moves a card to "In Progress" when work starts on it — a branch is created or
# commits referencing the card land — before any PR exists. Reads card-ref
# tokens from the branch name and commit messages.
class Github::PushSync
  def initialize(payload)
    @ref = payload["ref"]
    @ref_type = payload["ref_type"]
    @commits = payload["commits"] || []
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository && branch?

    linked_cards.each { |card| advance_to_in_progress(card) }
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    # "create" events fire for tags too; only branches carry work.
    def branch?
      @ref_type.nil? || @ref_type == "branch"
    end

    def linked_cards
      Github::References.extract(reference_text)
        .select(&:automate)
        .filter_map { |reference| Card.find_by_reference(reference.token) }
        .uniq
    end

    def reference_text
      [ branch_name, *@commits.map { |commit| commit["message"] } ].compact.join("\n")
    end

    def branch_name
      @ref.to_s.sub(%r{\Arefs/heads/}, "")
    end

    # Only nudge a card that hasn't entered the workflow yet; never demote a card
    # already in review or move a closed one.
    def advance_to_in_progress(card)
      return unless card.awaiting_triage?

      if column = in_progress_column(card)
        card.triage_into(column)
      end
    end

    def in_progress_column(card)
      name = Current.account.github_integration.setting("in_progress_column_name").presence || "In Progress"
      card.board.columns.find_by(name: name)
    end
end
