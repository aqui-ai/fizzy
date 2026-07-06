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
end
