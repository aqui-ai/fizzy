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

  test "the card page shows the reference and copy-branch action when GitHub is configured" do
    accounts("37s").github_integration.update!(credentials: { webhook_secret: "s" })

    get card_path(cards(:logo))

    assert_response :success
    assert_match cards(:logo).reference, @response.body
    assert_match cards(:logo).git_branch_name, @response.body
  end

  test "the card page hides the GitHub panel when GitHub is not configured and the card is unlinked" do
    get card_path(cards(:logo))

    assert_response :success
    assert_no_match "card-github", @response.body
  end
end
