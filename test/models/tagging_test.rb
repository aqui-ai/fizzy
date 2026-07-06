require "test_helper"

class TaggingTest < ActiveSupport::TestCase
  test "rejects a tag from another board" do
    foreign_tag = boards(:private).tags.create!(title: "foreign")
    tagging = cards(:logo).taggings.build(tag: foreign_tag)

    assert_not tagging.valid?
    assert_includes tagging.errors[:tag], "must belong to the card's board"
  end

  test "accepts a tag from the card's board" do
    tag = cards(:logo).board.tags.create!(title: "native")
    tagging = cards(:logo).taggings.build(tag: tag)

    assert tagging.valid?
  end
end
