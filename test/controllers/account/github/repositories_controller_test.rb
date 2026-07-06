require "test_helper"

class Account::Github::RepositoriesControllerTest < ActionDispatch::IntegrationTest
  test "admins map a repository to a board" do
    sign_in_as :kevin
    repository = accounts("37s").github_repositories.create!(github_id: 1, full_name: "aqui-ai/core")

    patch account_github_repository_path(repository), params: { github_repository: { board_id: boards(:writebook).id, active: "1" } }

    assert_equal boards(:writebook), repository.reload.board
    assert_predicate repository, :syncing?
  end

  test "members are forbidden" do
    sign_in_as :david
    repository = accounts("37s").github_repositories.create!(github_id: 1, full_name: "aqui-ai/core")

    patch account_github_repository_path(repository), params: { github_repository: { active: "0" } }

    assert_response :forbidden
  end
end
