class AddApiTokenToGithubConfigurations < ActiveRecord::Migration[8.2]
  def change
    add_column :github_configurations, :api_token, :string
  end
end
