require "test_helper"

class Github::PullRequestReviewSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", board: boards(:writebook))
    @pr = @repo.pull_requests.create!(github_id: 1, number: 3, state: "open")
  end

  test "records the submitted review state" do
    sync "submitted", "approved"

    assert_equal "approved", @pr.reload.review_state
  end

  test "records changes requested" do
    sync "submitted", "changes_requested"

    assert_equal "changes_requested", @pr.reload.review_state
  end

  test "dismissing clears the review state" do
    @pr.update!(review_state: "changes_requested")

    sync "dismissed", "changes_requested"

    assert_nil @pr.reload.review_state
  end

  test "ignores reviews for unknown pull requests" do
    assert_nothing_raised do
      Github::PullRequestReviewSync.new(
        "action" => "submitted", "review" => { "state" => "approved" },
        "pull_request" => { "number" => 999 }, "repository" => { "id" => 100 }
      ).process
    end
  end

  private
    def sync(action, state)
      Github::PullRequestReviewSync.new(
        "action" => action,
        "review" => { "state" => state },
        "pull_request" => { "number" => 3 },
        "repository" => { "id" => 100 }
      ).process
    end
end
