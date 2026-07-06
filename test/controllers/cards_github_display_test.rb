require "test_helper"

class CardsGithubDisplayTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :david
  end

  test "the card page shows linked GitHub issue metadata" do
    account = accounts("37s")
    repository = account.github_repositories.create!(github_id: 1, full_name: "aqui-ai/aqui-core", board: boards(:writebook))
    repository.issues.create!(github_id: 10, number: 42, state: "open", html_url: "https://github.com/aqui-ai/aqui-core/issues/42", card: cards(:logo))

    get card_path(cards(:logo))

    assert_response :success
    assert_match "aqui-ai/aqui-core#42", @response.body
  end
end
