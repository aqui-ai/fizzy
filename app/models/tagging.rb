class Tagging < ApplicationRecord
  belongs_to :account, default: -> { card.account }
  belongs_to :tag
  belongs_to :card, touch: true

  validate :tag_on_card_board

  private
    def tag_on_card_board
      if tag && card && tag.board_id != card.board_id
        errors.add(:tag, "must belong to the card's board")
      end
    end
end
