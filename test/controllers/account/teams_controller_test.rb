require "test_helper"

class Account::TeamsControllerTest < ActionDispatch::IntegrationTest
  test "admins can view and create teams" do
    sign_in_as :kevin
    get account_teams_path
    assert_response :success

    assert_difference -> { accounts("37s").teams.count }, +1 do
      post account_teams_path, params: { team: { name: "Engineering" } }
    end
    assert_redirected_to account_teams_path
  end

  test "a team can be nested under a parent" do
    sign_in_as :kevin
    parent = accounts("37s").teams.create!(name: "AQUI")

    post account_teams_path, params: { team: { name: "Ops", parent_id: parent.id } }

    assert_equal parent, accounts("37s").teams.find_by(name: "Ops").parent
  end

  test "admins can delete a team" do
    sign_in_as :kevin
    team = accounts("37s").teams.create!(name: "Temp")

    assert_difference -> { accounts("37s").teams.count }, -1 do
      delete account_team_path(team)
    end
  end

  test "members are forbidden" do
    sign_in_as :david
    get account_teams_path
    assert_response :forbidden
  end
end
