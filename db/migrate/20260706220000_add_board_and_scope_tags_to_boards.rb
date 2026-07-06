class AddBoardAndScopeTagsToBoards < ActiveRecord::Migration[8.2]
  DEFAULT_TAGS = %w[ blocked decision-required quotation payment evidence-attached evidence-missing deadline-risk waiting-external-party management-review ]

  class Board < ActiveRecord::Base
    self.table_name = "boards"
  end

  class Card < ActiveRecord::Base
    self.table_name = "cards"
  end

  class Tag < ActiveRecord::Base
    self.table_name = "tags"
  end

  class Tagging < ActiveRecord::Base
    self.table_name = "taggings"
  end

  class Filter < ActiveRecord::Base
    self.table_name = "filters"
    has_and_belongs_to_many :tags, class_name: "AddBoardAndScopeTagsToBoards::Tag", join_table: "filters_tags"
    has_and_belongs_to_many :boards, class_name: "AddBoardAndScopeTagsToBoards::Board", join_table: "boards_filters"
  end

  def up
    add_column :tags, :board_id, :uuid
    add_index :tags, :board_id
    remove_index :tags, name: "index_tags_on_account_id_and_title"

    split_tags_per_board
    seed_default_tags_on_existing_boards
    relink_filters
    Tag.where(board_id: nil).delete_all

    add_index :tags, [ :board_id, :title ], unique: true, name: "index_tags_on_board_id_and_title"
    change_column_null :tags, :board_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private
    # Repoint every tagging to a board-owned copy of its tag, keyed by the card's board.
    def split_tags_per_board
      Tagging.find_each do |tagging|
        card = Card.find_by(id: tagging.card_id)
        board = card && Board.find_by(id: card.board_id)
        old_tag = Tag.find_by(id: tagging.tag_id)
        next unless board && old_tag

        board_tag = find_or_create_board_tag(board, old_tag.title)
        tagging.update_columns(tag_id: board_tag.id) unless tagging.tag_id == board_tag.id
      end
    end

    def seed_default_tags_on_existing_boards
      Board.find_each do |board|
        DEFAULT_TAGS.each { |title| find_or_create_board_tag(board, title) }
      end
    end

    # Rewrite saved filters: swap each account tag for the same-title tags owned by the
    # filter's selected boards (or every same-title board tag when the filter has no boards).
    def relink_filters
      Filter.includes(:tags, :boards).find_each do |filter|
        old_tags = filter.tags.select { |tag| tag.board_id.nil? }
        next if old_tags.empty?

        board_ids = filter.boards.map(&:id)
        replacements = old_tags.flat_map { |tag| replacement_tag_ids(tag.title, board_ids) }

        say "filter #{filter.id}: no board tags matched #{old_tags.map(&:title).inspect}", true if replacements.empty?

        filter.tag_ids = (filter.tag_ids - old_tags.map(&:id) + replacements).uniq
      end
    end

    def replacement_tag_ids(title, board_ids)
      scope = Tag.where(title: title).where.not(board_id: nil)
      scope = scope.where(board_id: board_ids) if board_ids.any?
      scope.pluck(:id)
    end

    def find_or_create_board_tag(board, title)
      Tag.where(board_id: board.id, title: title).first ||
        Tag.create!(board_id: board.id, account_id: board.account_id, title: title)
    end
end
