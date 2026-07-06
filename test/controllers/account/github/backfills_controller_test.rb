require "test_helper"

class Account::Github::BackfillsControllerTest < ActionDispatch::IntegrationTest
  test "admins enqueue a backfill" do
    sign_in_as :kevin
    repository = accounts("37s").github_repositories.create!(github_id: 1, full_name: "a/b", board: boards(:writebook))

    assert_enqueued_with(job: Github::BackfillRepositoryJob) do
      post account_github_repository_backfill_path(repository)
    end

    assert_redirected_to account_github_integration_path
  end

  test "members are forbidden" do
    sign_in_as :david
    repository = accounts("37s").github_repositories.create!(github_id: 1, full_name: "a/b")

    post account_github_repository_backfill_path(repository)

    assert_response :forbidden
  end
end
