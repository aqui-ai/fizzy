class AddSyncIssuesToGithubRepositories < ActiveRecord::Migration[8.2]
  def change
    add_column :github_repositories, :sync_issues, :boolean, default: false, null: false
  end
end
