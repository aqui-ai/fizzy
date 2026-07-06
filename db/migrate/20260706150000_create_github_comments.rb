class CreateGithubComments < ActiveRecord::Migration[8.2]
  def change
    create_table :github_comments, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :issue_id, null: false
      t.uuid :comment_id, null: false
      t.bigint :github_id, null: false
      t.timestamps

      t.index [ :account_id, :github_id ], unique: true, name: "index_github_comments_on_account_and_github_id"
      t.index :issue_id, name: "index_github_comments_on_issue_id"
      t.index :comment_id, name: "index_github_comments_on_comment_id"
    end
  end
end
