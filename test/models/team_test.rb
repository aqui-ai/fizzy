require "test_helper"

class TeamTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
    Current.account = @account
  end

  test "self_and_descendant_ids walks the subtree" do
    company = @account.teams.create!(name: "AQUI")
    eng = @account.teams.create!(name: "Engineering", parent: company)
    backend = @account.teams.create!(name: "Backend", parent: eng)

    assert_equal [ company.id, eng.id, backend.id ].sort, company.self_and_descendant_ids.sort
    assert_equal [ eng, company ], backend.ancestors
  end

  test "members and leads" do
    team = @account.teams.create!(name: "Ops")
    team.memberships.create!(user: users(:david), lead: true)
    team.memberships.create!(user: users(:jz))

    assert_includes team.members, users(:david)
    assert_equal [ users(:david) ], team.leads.to_a
  end

  test "a user cannot be a member of the same team twice" do
    team = @account.teams.create!(name: "Ops")
    team.memberships.create!(user: users(:david))

    assert_not team.memberships.build(user: users(:david)).valid?
  end
end
