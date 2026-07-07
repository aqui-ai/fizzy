require "test_helper"

class Github::PullRequestSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @board = boards(:writebook)
    @account.integrations.create!(provider: "github",
      settings: { "in_progress_column_name" => "In progress", "in_review_column_name" => "Review" })
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", board: @board, sync_issues: true)

    Github::IssueSync.new(
      "action" => "opened",
      "issue" => { "id" => 50, "number" => 7, "title" => "Feature", "state" => "open", "labels" => [], "assignees" => [] },
      "repository" => { "id" => 100 }
    ).process
    @card = @repo.issues.find_by(number: 7).card
  end

  # --- Legacy GitHub-issue linking (issue-mirror mode) ---

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

  # --- Card-reference linking (card-as-hub) ---

  test "links via a card-ref token in the branch name without any issue" do
    card = native_card

    sync "opened", number: 5, title: "Some work", state: "open", head_ref: card.git_branch_name

    assert_equal card, @repo.pull_requests.find_by(number: 5).card
  end

  test "opened as draft moves the card-ref-linked card to the in-progress column" do
    card = native_card

    sync "opened", number: 5, title: card.reference, state: "open", draft: true, head_ref: card.git_branch_name

    assert_equal columns(:writebook_in_progress), card.reload.column
  end

  test "ready_for_review moves a card-ref-linked card to the review column" do
    card = native_card

    sync "ready_for_review", number: 5, title: "Fixes #{card.reference}", state: "open", head_ref: card.git_branch_name

    assert_equal columns(:writebook_review), card.reload.column
  end

  test "converted_to_draft moves the card back to the in-progress column" do
    card = native_card
    sync "ready_for_review", number: 5, title: card.reference, state: "open", head_ref: card.git_branch_name
    sync "converted_to_draft", number: 5, title: card.reference, state: "open", head_ref: card.git_branch_name

    assert_equal columns(:writebook_in_progress), card.reload.column
  end

  test "a non-closing keyword links the card without moving it" do
    card = native_card

    sync "ready_for_review", number: 5, title: "Related to #{card.reference}", state: "open", head_ref: "topic-branch"

    assert_equal card, @repo.pull_requests.find_by(number: 5).card
    assert_nil card.reload.column
  end

  test "merging into the default branch closes the card" do
    card = native_card
    sync "opened", number: 5, title: "Fixes #{card.reference}", state: "open", head_ref: card.git_branch_name
    sync "closed", number: 5, title: "Fixes #{card.reference}", state: "closed", merged: true,
      base_ref: "main", default_branch: "main"

    assert_predicate card.reload, :closed?
  end

  test "merging into a non-default branch does not close the card" do
    card = native_card
    sync "opened", number: 5, title: "Fixes #{card.reference}", state: "open", head_ref: card.git_branch_name
    sync "closed", number: 5, title: "Fixes #{card.reference}", state: "closed", merged: true,
      base_ref: "release/1.0", default_branch: "main"

    assert_not card.reload.closed?
  end

  private
    def native_card
      @board.cards.create!(title: "Native work", creator: Current.user, status: "published")
    end

    def sync(action, number:, title:, state:, merged: false, draft: false, head_ref: "feature", base_ref: nil, default_branch: nil)
      pull_request = {
        "id" => number * 10, "number" => number, "title" => title, "state" => state,
        "merged" => merged, "draft" => draft, "html_url" => "https://github.com/x/pull/#{number}",
        "head" => { "ref" => head_ref },
        "base" => { "ref" => base_ref, "repo" => { "default_branch" => default_branch } }
      }

      Github::PullRequestSync.new(
        "action" => action,
        "pull_request" => pull_request,
        "repository" => { "id" => 100 }
      ).process
    end
end
