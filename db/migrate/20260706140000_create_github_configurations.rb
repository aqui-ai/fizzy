class CreateGithubConfigurations < ActiveRecord::Migration[8.2]
  def change
    create_table :github_configurations, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :webhook_secret
      t.string :in_review_column_name
      t.timestamps

      t.index :account_id, unique: true, name: "index_github_configurations_on_account_id"
    end
  end
end
