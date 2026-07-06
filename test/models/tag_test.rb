require "test_helper"

class TagTest < ActiveSupport::TestCase
  setup do
    @board = boards(:writebook)
  end

  test "downcase title" do
    assert_equal "a tag", @board.tags.create!(title: "A TAG").title
  end

  test "belongs to a board" do
    assert_equal @board, tags(:web).board
  end

  test "defaults account to the board's account" do
    assert_equal @board.account, @board.tags.create!(title: "a tag").account
  end

  test "same title is allowed on different boards" do
    other_board = boards(:private)

    assert_nothing_raised do
      @board.tags.create!(title: "duplicate")
      other_board.tags.create!(title: "duplicate")
    end
  end

  test "duplicate title is rejected within a board" do
    @board.tags.create!(title: "unique")

    assert_raises ActiveRecord::RecordInvalid do
      @board.tags.create!(title: "unique")
    end
  end

  test ".unused returns tags not associated with any cards" do
    unused = @board.tags.create!(title: "unused")

    unused_tags = Tag.unused

    assert_includes unused_tags, unused
    assert_not_includes unused_tags, tags(:web)
    assert_not_includes unused_tags, tags(:mobile)
  end

  test ".unused returns empty relation if all tags are used" do
    assert_empty Tag.unused
  end
end
