require "test_helper"

class Github::UserLinkTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    @user = users(:david)
  end

  test "maps a github login to a user within the account" do
    @account.github_user_links.create!(user: @user, github_login: "dhh", github_id: 5)

    assert_equal @user, @account.github_user_links.user_for("dhh")
  end

  test "github_login is unique per account" do
    @account.github_user_links.create!(user: @user, github_login: "dhh")

    assert_not @account.github_user_links.build(user: users(:jz), github_login: "dhh").valid?
  end
end
