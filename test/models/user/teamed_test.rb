require "test_helper"

class User::TeamedTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
    @company = @account.teams.create!(name: "AQUI")
    @engineering = @account.teams.create!(name: "Engineering", parent: @company)
  end

  test "admins manage and are accountable for everyone" do
    assert_predicate users(:kevin), :manages_accountability?
    assert_equal @account.users.active.pluck(:id).sort, users(:kevin).accountable_users.pluck(:id).sort
  end

  test "a team lead is accountable for their subtree members" do
    @company.memberships.create!(user: users(:david), lead: true)
    @engineering.memberships.create!(user: users(:jz))

    assert_predicate users(:david), :manages_accountability?
    accountable = users(:david).accountable_users
    assert_includes accountable, users(:jz)
    assert_not_includes accountable, users(:jason)
  end

  test "a plain member manages nobody but themselves" do
    assert_not_predicate users(:jz), :manages_accountability?
    assert_equal [ users(:jz).id ], users(:jz).accountable_users.pluck(:id)
  end
end
