class AddPriorityToCards < ActiveRecord::Migration[8.2]
  def change
    add_column :cards, :priority, :string, default: "none", null: false
  end
end
