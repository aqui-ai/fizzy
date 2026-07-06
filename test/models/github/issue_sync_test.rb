require "test_helper"

class Github::IssueSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @board = boards(:writebook)
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", name: "core", board: @board)
  end

  test "applies GitHub labels as tags plus a repo tag" do
    Github::IssueSync.new(
      "action" => "opened",
      "issue" => { "id" => 60, "number" => 6, "title" => "T", "state" => "open",
                   "labels" => [ { "name" => "Bug" }, { "name" => "urgent" } ], "assignees" => [] },
      "repository" => { "id" => 100 }
    ).process

    titles = @repo.issues.find_by(number: 6).card.tags.pluck(:title)
    assert_includes titles, "bug"
    assert_includes titles, "urgent"
    assert_includes titles, "repo:core"
  end

  test "assigns mapped GitHub users to the card" do
    @account.github_user_links.create!(github_login: "dhh", user: users(:david))

    assignees_sync 6, [ "dhh" ]

    assert_includes @repo.issues.find_by(number: 6).card.assignees, users(:david)
  end

  test "unassigning in GitHub removes only github-managed assignees" do
    @account.github_user_links.create!(github_login: "dhh", user: users(:david))
    assignees_sync 6, [ "dhh" ]
    card = @repo.issues.find_by(number: 6).card
    card.toggle_assignment(users(:jz)) # a Fizzy-only assignee, no GitHub link

    assignees_sync 6, []

    card.reload
    assert_not_includes card.assignees, users(:david)
    assert_includes card.assignees, users(:jz)
  end

  test "opened creates and links a card in the mapped board" do
    assert_difference -> { @board.cards.count }, +1 do
      sync "opened", number: 5, title: "Fix login", state: "open"
    end

    issue = @repo.issues.find_by(number: 5)
    assert_equal "Fix login", issue.card.title
    assert_equal @board, issue.card.board
  end

  test "edited updates the linked card title" do
    sync "opened", number: 5, title: "Old title", state: "open"
    sync "edited", number: 5, title: "New title", state: "open"

    assert_equal "New title", @repo.issues.find_by(number: 5).card.title
  end

  test "closed closes the linked card" do
    sync "opened", number: 5, title: "X", state: "open"
    sync "closed", number: 5, title: "X", state: "closed"

    assert_predicate @repo.issues.find_by(number: 5).card, :closed?
  end

  test "reopened reopens the linked card" do
    sync "opened", number: 5, title: "X", state: "open"
    sync "closed", number: 5, title: "X", state: "closed"
    sync "reopened", number: 5, title: "X", state: "open"

    assert_not @repo.issues.find_by(number: 5).card.closed?
  end

  test "stores labels and assignees" do
    Github::IssueSync.new(
      "action" => "opened",
      "issue" => { "id" => 1, "number" => 9, "title" => "T", "state" => "open",
                   "labels" => [ { "name" => "bug" }, { "name" => "urgent" } ],
                   "assignees" => [ { "login" => "dhh" } ] },
      "repository" => { "id" => 100 }
    ).process

    issue = @repo.issues.find_by(number: 9)
    assert_equal %w[ bug urgent ], issue.labels
    assert_equal %w[ dhh ], issue.assignees
  end

  test "auto-registers unmapped repositories without creating a card" do
    assert_no_difference -> { Card.count } do
      Github::IssueSync.new(
        "action" => "opened",
        "issue" => { "id" => 1, "number" => 1, "title" => "T", "state" => "open", "labels" => [], "assignees" => [] },
        "repository" => { "id" => 999, "full_name" => "other/repo" }
      ).process
    end

    repository = @account.github_repositories.find_by(github_id: 999)
    assert_not_nil repository
    assert_not repository.syncing?
  end

  private
    def assignees_sync(number, logins)
      action = @repo.issues.exists?(number: number) ? "assigned" : "opened"
      Github::IssueSync.new(
        "action" => action,
        "issue" => { "id" => number * 10, "number" => number, "title" => "T", "state" => "open",
                     "labels" => [], "assignees" => logins.map { |login| { "login" => login } } },
        "repository" => { "id" => 100 }
      ).process
    end

    def sync(action, number:, title:, state:)
      Github::IssueSync.new(
        "action" => action,
        "issue" => { "id" => number * 10, "number" => number, "title" => title, "state" => state,
                     "html_url" => "https://github.com/x/#{number}", "labels" => [], "assignees" => [] },
        "repository" => { "id" => 100 }
      ).process
    end
end
