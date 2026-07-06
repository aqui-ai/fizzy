class CreateGithubTables < ActiveRecord::Migration[8.2]
  def change
    create_table :github_repositories, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id
      t.bigint :github_id, null: false
      t.string :owner
      t.string :name
      t.string :full_name, null: false
      t.string :html_url
      t.boolean :active, default: true, null: false
      t.timestamps

      t.index [ :account_id, :github_id ], unique: true, name: "index_github_repositories_on_account_and_github_id"
      t.index [ :account_id, :full_name ], unique: true, name: "index_github_repositories_on_account_and_full_name"
    end

    create_table :github_issues, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id
      t.uuid :card_id
      t.uuid :repository_id, null: false
      t.bigint :github_id, null: false
      t.integer :number, null: false
      t.string :title
      t.text :body
      t.string :html_url
      t.string :state
      t.json :labels
      t.json :assignees
      t.datetime :opened_at
      t.datetime :closed_at
      t.datetime :last_synced_at
      t.timestamps

      t.index [ :account_id, :repository_id, :number ], unique: true, name: "index_github_issues_on_account_repo_number"
      t.index [ :account_id, :card_id ], name: "index_github_issues_on_account_and_card_id"
      t.index :repository_id, name: "index_github_issues_on_repository_id"
    end

    create_table :github_pull_requests, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id
      t.uuid :card_id
      t.uuid :repository_id, null: false
      t.bigint :github_id, null: false
      t.integer :number, null: false
      t.string :title
      t.string :html_url
      t.string :state
      t.boolean :merged, default: false, null: false
      t.datetime :merged_at
      t.string :head_ref
      t.datetime :last_synced_at
      t.timestamps

      t.index [ :account_id, :repository_id, :number ], unique: true, name: "index_github_pull_requests_on_account_repo_number"
      t.index :repository_id, name: "index_github_pull_requests_on_repository_id"
    end

    create_table :github_user_links, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :user_id, null: false
      t.bigint :github_id
      t.string :github_login, null: false
      t.timestamps

      t.index [ :account_id, :github_login ], unique: true, name: "index_github_user_links_on_account_and_login"
      t.index :user_id, name: "index_github_user_links_on_user_id"
    end
  end
end
