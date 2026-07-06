require "test_helper"

class Account::Github::UserLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "admins link a github user" do
    assert_difference -> { Github::UserLink.count }, +1 do
      post account_github_user_links_path, params: { github_user_link: { github_login: "dhh", user_id: users(:david).id } }
    end

    assert_equal users(:david), accounts("37s").github_user_links.user_for("dhh")
  end

  test "admins unlink a github user" do
    link = accounts("37s").github_user_links.create!(github_login: "dhh", user: users(:david))

    assert_difference -> { Github::UserLink.count }, -1 do
      delete account_github_user_link_path(link)
    end
  end
end
