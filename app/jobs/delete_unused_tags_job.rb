class DeleteUnusedTagsJob < ApplicationJob
  def perform
    Tag.unused.where.not(title: Board::DEFAULT_TAGS).find_each do |tag|
      tag.destroy!
    end
  end
end
