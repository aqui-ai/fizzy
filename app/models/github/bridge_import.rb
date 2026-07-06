class Github::BridgeImport
  Result = Data.define(:imported, :skipped)

  def initialize(account, mappings)
    @account = account
    @mappings = mappings
  end

  def run
    imported = 0
    skipped = 0

    Current.with_account(@account) do
      @mappings.each do |mapping|
        if import(mapping)
          imported += 1
        else
          skipped += 1
        end
      end
    end

    Result.new(imported: imported, skipped: skipped)
  end

  private
    def import(mapping)
      card = @account.cards.find_by(number: mapping["card_number"])
      return false unless card

      repository = repository_for(mapping)
      repository.issues.find_or_initialize_by(number: mapping["issue_number"]).update!(
        github_id: mapping["issue_github_id"],
        title: mapping["issue_title"],
        state: mapping["issue_state"],
        html_url: mapping["issue_html_url"],
        board_id: repository.board_id,
        card: card
      )
      true
    end

    def repository_for(mapping)
      @account.github_repositories.find_or_create_by!(github_id: mapping["repo_github_id"]) do |repository|
        repository.full_name = mapping["repo_full_name"]
        repository.owner, repository.name = mapping["repo_full_name"].to_s.split("/", 2)
      end
    end
end
