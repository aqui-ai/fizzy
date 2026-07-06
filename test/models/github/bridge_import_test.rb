require "test_helper"

class Github::BridgeImportTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    @card = cards(:logo)
  end

  test "imports mappings and links existing cards by number" do
    mappings = [ {
      "repo_full_name" => "aqui-ai/aqui-core", "repo_github_id" => 100,
      "issue_number" => 42, "issue_github_id" => 999, "issue_title" => "Legacy issue",
      "issue_state" => "open", "issue_html_url" => "https://github.com/aqui-ai/aqui-core/issues/42",
      "card_number" => @card.number
    } ]

    result = Github::BridgeImport.new(@account, mappings).run

    assert_equal 1, result.imported
    issue = @account.github_repositories.find_by(github_id: 100).issues.find_by(number: 42)
    assert_equal @card, issue.card
    assert_equal "aqui-ai", issue.repository.owner
  end

  test "skips mappings without a matching card" do
    mappings = [ {
      "repo_full_name" => "a/b", "repo_github_id" => 100,
      "issue_number" => 1, "issue_github_id" => 1, "card_number" => 999_999
    } ]

    result = Github::BridgeImport.new(@account, mappings).run

    assert_equal 0, result.imported
    assert_equal 1, result.skipped
  end
end
