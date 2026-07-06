require "test_helper"

class Github::CommentSyncTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    Current.user = @account.system_user
    @repo = @account.github_repositories.create!(github_id: 100, full_name: "aqui-ai/core", name: "core", board: boards(:writebook))
    Github::IssueSync.new(
      "action" => "opened",
      "issue" => { "id" => 50, "number" => 7, "title" => "T", "state" => "open", "labels" => [], "assignees" => [] },
      "repository" => { "id" => 100 }
    ).process
    @card = @repo.issues.find_by(number: 7).card
  end

  test "created mirrors a GitHub comment onto the card" do
    assert_difference -> { @card.comments.count }, +1 do
      comment_sync "created", id: 900, body: "Looks good to me"
    end

    assert_equal 1, @account.github_comments.where(github_id: 900).count
    assert_includes latest_comment.body.to_plain_text, "Looks good to me"
    assert_includes latest_comment.body.to_plain_text, "via GitHub"
  end

  test "created is idempotent for the same GitHub comment" do
    comment_sync "created", id: 900, body: "x"

    assert_no_difference -> { @card.comments.count } do
      comment_sync "created", id: 900, body: "x"
    end
  end

  test "edited updates the mirrored comment" do
    comment_sync "created", id: 900, body: "first"
    comment_sync "edited", id: 900, body: "second"

    assert_includes latest_comment.body.to_plain_text, "second"
  end

  test "deleted removes the mirrored comment" do
    comment_sync "created", id: 900, body: "bye"

    assert_difference -> { @card.comments.count }, -1 do
      comment_sync "deleted", id: 900, body: "bye"
    end
  end

  test "attributes the comment to the mapped user" do
    @account.github_user_links.create!(github_login: "dhh", user: users(:david))

    comment_sync "created", id: 901, body: "hi", login: "dhh"

    assert_equal users(:david), latest_comment.creator
  end

  private
    def latest_comment
      @card.comments.order(:created_at).last
    end

    def comment_sync(action, id:, body:, login: "octocat")
      Github::CommentSync.new(
        "action" => action,
        "comment" => { "id" => id, "body" => body, "html_url" => "https://github.com/x/#{id}", "user" => { "login" => login } },
        "issue" => { "number" => 7 },
        "repository" => { "id" => 100 }
      ).process
    end
end
