class AddStatusToGithubPullRequests < ActiveRecord::Migration[8.2]
  def change
    add_column :github_pull_requests, :draft, :boolean, default: false, null: false
    add_column :github_pull_requests, :review_state, :string
    add_column :github_pull_requests, :checks_state, :string
  end
end
