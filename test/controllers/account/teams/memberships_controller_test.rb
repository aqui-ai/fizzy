require "test_helper"

class Account::Teams::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @team = accounts("37s").teams.create!(name: "Ops")
  end

  test "admins add a member as lead" do
    sign_in_as :kevin

    assert_difference -> { @team.memberships.count }, +1 do
      post account_team_memberships_path(@team), params: { team_membership: { user_id: users(:david).id, lead: "1" } }
    end
    assert_predicate @team.memberships.last, :lead?
  end

  test "admins toggle lead" do
    sign_in_as :kevin
    membership = @team.memberships.create!(user: users(:david), lead: false)

    patch account_team_membership_path(@team, membership), params: { team_membership: { lead: "1" } }

    assert_predicate membership.reload, :lead?
  end

  test "admins remove a member" do
    sign_in_as :kevin
    membership = @team.memberships.create!(user: users(:david))

    assert_difference -> { @team.memberships.count }, -1 do
      delete account_team_membership_path(@team, membership)
    end
  end

  test "members are forbidden" do
    sign_in_as :david
    post account_team_memberships_path(@team), params: { team_membership: { user_id: users(:jz).id } }
    assert_response :forbidden
  end
end
