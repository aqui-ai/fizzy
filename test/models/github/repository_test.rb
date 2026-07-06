require "test_helper"

class Github::RepositoryTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
  end

  test "creates a repository, active by default" do
    repo = @account.github_repositories.create!(github_id: 1, full_name: "aqui-ai/aqui-core", name: "aqui-core", owner: "aqui-ai")

    assert repo.persisted?
    assert_predicate repo, :active?
  end

  test "github_id is unique per account" do
    @account.github_repositories.create!(github_id: 1, full_name: "a/b")

    assert_not @account.github_repositories.build(github_id: 1, full_name: "a/c").valid?
  end

  test "full_name is unique per account" do
    @account.github_repositories.create!(github_id: 1, full_name: "a/b")

    assert_not @account.github_repositories.build(github_id: 2, full_name: "a/b").valid?
  end

  test "active scope excludes inactive repositories" do
    active = @account.github_repositories.create!(github_id: 1, full_name: "a/b")
    inactive = @account.github_repositories.create!(github_id: 2, full_name: "a/c", active: false)

    assert_includes @account.github_repositories.active, active
    assert_not_includes @account.github_repositories.active, inactive
  end
end
