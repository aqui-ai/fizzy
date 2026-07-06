require "test_helper"

class Report::GithubTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", name: "core", board: boards(:writebook))
  end

  test "counts open and closed linked cards by repository" do
    create_issue 1
    closed = create_issue 2
    closed.card.close

    report = Report::Github.new(@account)
    assert_equal({ "aqui-ai/core" => 1 }, report.open_cards_by_repository)
    assert_equal({ "aqui-ai/core" => 1 }, report.closed_cards_by_repository)
  end

  test "counts pull request state" do
    card = create_issue(1).card
    @repo.pull_requests.create!(github_id: 10, number: 5, state: "open", card: card)
    @repo.pull_requests.create!(github_id: 11, number: 6, state: "closed", merged: true, merged_at: 2.days.ago, card: card)

    report = Report::Github.new(@account)
    assert_equal 1, report.open_pull_requests
    assert_equal 1, report.in_review
    assert_equal 1, report.merged_this_week
    assert_equal 1, report.linked_repositories
  end

  private
    def create_issue(number)
      Github::IssueSync.new(
        "action" => "opened",
        "issue" => { "id" => number * 10, "number" => number, "title" => "T#{number}", "state" => "open", "labels" => [], "assignees" => [] },
        "repository" => { "id" => 100 }
      ).process
      @repo.issues.find_by(number: number)
    end
end
