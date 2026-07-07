require "test_helper"

class Github::ChecksSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", board: boards(:writebook))
    @pr = @repo.pull_requests.create!(github_id: 1, number: 3, state: "open", head_ref: "feature")
  end

  test "records a passing check suite by PR number" do
    check_suite "completed", "success", pull_requests: [ { "number" => 3 } ]

    assert_equal "success", @pr.reload.checks_state
  end

  test "records a failing check suite" do
    check_suite "completed", "failure", pull_requests: [ { "number" => 3 } ]

    assert_equal "failure", @pr.reload.checks_state
  end

  test "ignores in-progress check suites" do
    check_suite "in_progress", nil, pull_requests: [ { "number" => 3 } ]

    assert_nil @pr.reload.checks_state
  end

  test "records a legacy status event by head branch" do
    Github::ChecksSync.new(
      "state" => "pending", "branches" => [ { "name" => "feature" } ], "repository" => { "id" => 100 }
    ).process

    assert_equal "pending", @pr.reload.checks_state
  end

  private
    def check_suite(status, conclusion, pull_requests:)
      Github::ChecksSync.new(
        "check_suite" => { "status" => status, "conclusion" => conclusion, "pull_requests" => pull_requests },
        "repository" => { "id" => 100 }
      ).process
    end
end
