require "test_helper"

class Github::PullRequestSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @board = boards(:writebook)
    @account.integrations.create!(provider: "github", settings: { "in_review_column_name" => "Review" })
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", board: @board)

    Github::IssueSync.new(
      "action" => "opened",
      "issue" => { "id" => 50, "number" => 7, "title" => "Feature", "state" => "open", "labels" => [], "assignees" => [] },
      "repository" => { "id" => 100 }
    ).process
    @card = @repo.issues.find_by(number: 7).card
  end

  test "opened links the PR to the referenced issue's card" do
    sync "opened", number: 3, title: "Add feature (closes #7)", state: "open"

    assert_equal @card, @repo.pull_requests.find_by(number: 3).card
  end

  test "ready_for_review moves the linked card to the review column" do
    sync "ready_for_review", number: 3, title: "closes #7", state: "open"

    assert_equal columns(:writebook_review), @card.reload.column
  end

  test "merged closes the linked card" do
    sync "opened", number: 3, title: "closes #7", state: "open"
    sync "closed", number: 3, title: "closes #7", state: "closed", merged: true

    assert_predicate @card.reload, :closed?
  end

  test "closed without merge leaves the card open" do
    sync "opened", number: 3, title: "closes #7", state: "open"
    sync "closed", number: 3, title: "closes #7", state: "closed", merged: false

    assert_not @card.reload.closed?
  end

  private
    def sync(action, number:, title:, state:, merged: false)
      Github::PullRequestSync.new(
        "action" => action,
        "pull_request" => { "id" => number * 10, "number" => number, "title" => title, "state" => state,
                            "merged" => merged, "html_url" => "https://github.com/x/pull/#{number}", "head" => { "ref" => "feature" } },
        "repository" => { "id" => 100 }
      ).process
    end
end
