require "test_helper"

class Github::PushSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @board = boards(:writebook)
    @account.integrations.create!(provider: "github", settings: { "in_progress_column_name" => "In progress" })
    @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", board: @board)
    @card = @board.cards.create!(title: "Native work", creator: Current.user, status: "published")
  end

  test "a branch name reference moves an untriaged card to in progress" do
    push ref: "refs/heads/#{@card.git_branch_name}"

    assert_equal columns(:writebook_in_progress), @card.reload.column
  end

  test "a commit message reference moves an untriaged card to in progress" do
    push ref: "refs/heads/some-branch", commits: [ { "message" => "Start #{@card.reference}" } ]

    assert_equal columns(:writebook_in_progress), @card.reload.column
  end

  test "a branch created event moves the card" do
    Github::PushSync.new(
      "ref" => @card.git_branch_name, "ref_type" => "branch", "repository" => { "id" => 100 }
    ).process

    assert_equal columns(:writebook_in_progress), @card.reload.column
  end

  test "a tag created event does nothing" do
    Github::PushSync.new(
      "ref" => @card.git_branch_name, "ref_type" => "tag", "repository" => { "id" => 100 }
    ).process

    assert_nil @card.reload.column
  end

  test "does not demote a card already in another column" do
    @card.triage_into(columns(:writebook_review))

    push ref: "refs/heads/#{@card.git_branch_name}"

    assert_equal columns(:writebook_review), @card.reload.column
  end

  test "a non-closing keyword in a commit does not move the card" do
    push ref: "refs/heads/topic", commits: [ { "message" => "Related to #{@card.reference}" } ]

    assert_nil @card.reload.column
  end

  private
    def push(ref:, commits: [])
      Github::PushSync.new("ref" => ref, "commits" => commits, "repository" => { "id" => 100 }).process
    end
end
