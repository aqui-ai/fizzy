require "test_helper"

class DeleteUnusedTagsJobTest < ActiveJob::TestCase
  test "deletes tags that are not used by any cards" do
    unused = boards(:writebook).tags.create!(title: "unused")

    assert_changes -> { Tag.count }, -1 do
      DeleteUnusedTagsJob.perform_now
    end

    assert_not Tag.exists?(unused.id), "Unused tag should be deleted"
  end

  test "keeps unused default tags" do
    kept = boards(:writebook).tags.create!(title: Board::DEFAULT_TAGS.first)

    DeleteUnusedTagsJob.perform_now

    assert Tag.exists?(kept.id), "Default tag should be preserved even when unused"
  end
end
