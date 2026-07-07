require "test_helper"

class Card::GithubLinkableTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    @card = cards(:logo)
    @repo = @account.github_repositories.create!(github_id: 1, full_name: "a/b")
  end

  test "links an issue and pull requests to a card" do
    @repo.issues.create!(github_id: 10, number: 1, card: @card)
    @repo.pull_requests.create!(github_id: 20, number: 2, card: @card)

    assert_equal 1, @card.reload.github_issue.number
    assert_equal 1, @card.github_pull_requests.count
    assert_predicate @card, :github_linked?
  end

  test "cards without github links are not linked" do
    assert_not cards(:layout).github_linked?
  end

  test "reference combines the board key and card number" do
    assert_equal "WRITE-#{@card.number}", @card.reference
  end

  test "git branch name embeds key, number and slug" do
    assert_equal "write-#{@card.number}-#{@card.title.parameterize}", @card.git_branch_name
  end

  test "find_by_reference resolves a KEY-NUMBER token" do
    Current.set(account: @account) do
      assert_equal @card, Card.find_by_reference(@card.reference)
    end
  end

  test "find_by_reference rejects a mismatched key" do
    Current.set(account: @account) do
      assert_nil Card.find_by_reference("AGENT-#{@card.number}")
    end
  end

  test "find_by_reference returns nil for an unknown number" do
    Current.set(account: @account) do
      assert_nil Card.find_by_reference("WRITE-99999")
    end
  end

  test "find_by_reference returns nil for a malformed token" do
    Current.set(account: @account) do
      assert_nil Card.find_by_reference("not-a-ref")
    end
  end
end
