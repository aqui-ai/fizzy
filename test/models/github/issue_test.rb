require "test_helper"

class Github::IssueTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    @repo = @account.github_repositories.create!(github_id: 1, full_name: "a/b")
  end

  test "account defaults from the repository" do
    issue = @repo.issues.create!(github_id: 10, number: 1, state: "open")

    assert_equal @account, issue.account
  end

  test "number is unique per repository" do
    @repo.issues.create!(github_id: 10, number: 1)

    assert_not @repo.issues.build(github_id: 11, number: 1).valid?
  end

  test "open? and closed? reflect state" do
    assert_predicate @repo.issues.create!(github_id: 10, number: 1, state: "open"), :open?
    assert_predicate @repo.issues.create!(github_id: 11, number: 2, state: "closed"), :closed?
  end
end
