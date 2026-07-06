class CreateTeams < ActiveRecord::Migration[8.2]
  def change
    create_table :teams, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :parent_id
      t.string :name, null: false
      t.timestamps

      t.index :account_id, name: "index_teams_on_account_id"
      t.index :parent_id, name: "index_teams_on_parent_id"
    end

    create_table :team_memberships, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :team_id, null: false
      t.uuid :user_id, null: false
      t.boolean :lead, default: false, null: false
      t.timestamps

      t.index [ :team_id, :user_id ], unique: true, name: "index_team_memberships_on_team_and_user"
      t.index :user_id, name: "index_team_memberships_on_user_id"
    end
  end
end
