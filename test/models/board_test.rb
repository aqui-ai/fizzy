require "test_helper"

class BoardTest < ActiveSupport::TestCase
  setup do
    @board = accounts("37s").boards.create!(name: "Ops", all_access: true, creator: users(:kevin))
  end

  test "seeds default tags on creation" do
    assert_equal Board::DEFAULT_TAGS.sort, @board.tags.pluck(:title).sort
  end

  test "seeding is idempotent" do
    assert_no_difference -> { @board.tags.count } do
      @board.seed_default_tags
    end
  end

  test "tags are owned by the board" do
    tag = @board.tags.create!(title: "owned")

    assert_includes @board.reload.tags, tag
  end

  test "auto-assigns a key derived from the name" do
    board = accounts("37s").boards.create!(name: "aqui-core", all_access: true, creator: users(:kevin))

    assert_equal "CORE", board.key
  end

  test "uses the last word of a multi-word name for the key" do
    assert_equal "AGENT", accounts("37s").boards.create!(name: "aqui agent", all_access: true, creator: users(:kevin)).key
  end

  test "suffixes the key to keep it unique within an account" do
    first = accounts("37s").boards.create!(name: "Backend Dev", all_access: true, creator: users(:kevin))
    second = accounts("37s").boards.create!(name: "Frontend Dev", all_access: true, creator: users(:kevin))

    assert_equal "DEV", first.key
    assert_equal "DEV2", second.key
  end

  test "normalizes an explicit key to uppercase" do
    board = accounts("37s").boards.create!(name: "Sales", key: "sales", all_access: true, creator: users(:kevin))

    assert_equal "SALES", board.key
  end

  test "rejects an invalid key format" do
    board = accounts("37s").boards.build(name: "Ops", key: "1BAD", all_access: true, creator: users(:kevin))

    assert_not board.valid?
    assert_includes board.errors.attribute_names, :key
  end

  test "rejects a duplicate key within the same account" do
    duplicate = accounts("37s").boards.build(name: "Another", key: "WRITE", all_access: true, creator: users(:kevin))

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :key
  end

  test "allows the same key in different accounts" do
    assert_nothing_raised do
      accounts("initech").boards.create!(name: "Writebook clone", key: "WRITE", all_access: true, creator: users(:mike))
    end
  end
end
