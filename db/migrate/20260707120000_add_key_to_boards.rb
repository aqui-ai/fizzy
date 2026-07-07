class AddKeyToBoards < ActiveRecord::Migration[8.2]
  KEY_MAX_LENGTH = 6

  class Board < ActiveRecord::Base
    self.table_name = "boards"
  end

  def up
    add_column :boards, :key, :string

    backfill_keys

    add_index :boards, [ :account_id, :key ], unique: true, name: "index_boards_on_account_id_and_key"
    change_column_null :boards, :key, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private
    def backfill_keys
      Board.where(key: nil).order(:created_at).group_by(&:account_id).each do |account_id, boards|
        assigned = []
        boards.each do |board|
          key = generate_key(board.name, account_id, assigned)
          board.update_columns(key: key)
          assigned << key
        end
      end
    end

    def generate_key(name, account_id, assigned)
      base = key_base_from(name)
      candidate, suffix = base, 1

      while assigned.include?(candidate) || Board.where(account_id: account_id).where.not(key: nil).exists?(key: candidate)
        suffix += 1
        candidate = "#{base.first(KEY_MAX_LENGTH - suffix.to_s.length)}#{suffix}"
      end

      candidate
    end

    def key_base_from(name)
      words = name.to_s.scan(/[A-Za-z0-9]+/)
      base = (words.length > 1 ? words.last : words.first).to_s.upcase
      base = "BOARD#{base}" unless base.match?(/\A[A-Z]/)
      base.first(KEY_MAX_LENGTH)
    end
end
