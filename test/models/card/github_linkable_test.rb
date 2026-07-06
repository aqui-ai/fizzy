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
end
