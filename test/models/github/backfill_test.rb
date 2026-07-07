require "test_helper"

class Github::BackfillTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @account.integrations.create!(provider: "github", credentials: { "api_token" => "ghp_test" })
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", name: "core", board: boards(:writebook), sync_issues: true)
  end

  test "imports issues from the GitHub API as cards" do
    stub_issues [
      { id: 1, number: 11, title: "Open issue", state: "open", html_url: "https://x/11", labels: [], assignees: [] },
      { id: 2, number: 12, title: "Closed issue", state: "closed", html_url: "https://x/12", labels: [], assignees: [] }
    ]
    stub_pulls []

    assert_difference -> { @repo.issues.count }, +2 do
      Github::Backfill.new(@repo).run
    end

    assert_equal "Open issue", @repo.issues.find_by(number: 11).card.title
    assert_predicate @repo.issues.find_by(number: 12).card, :closed?
  end

  test "does nothing without an API token" do
    @account.github_integration.update!(credentials: {})

    Github::Backfill.new(@repo).run

    assert_equal 0, @repo.issues.count
  end

  private
    def stub_issues(body)
      stub_request(:get, "https://api.github.com/repos/aqui-ai/core/issues")
        .with(query: { state: "all", per_page: "100" })
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_pulls(body)
      stub_request(:get, "https://api.github.com/repos/aqui-ai/core/pulls")
        .with(query: { state: "all", per_page: "100" })
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end
end
