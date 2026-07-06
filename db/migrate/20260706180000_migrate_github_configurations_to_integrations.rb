class MigrateGithubConfigurationsToIntegrations < ActiveRecord::Migration[8.2]
  def up
    configuration = Class.new(ActiveRecord::Base) { self.table_name = "github_configurations" }
    integration = Class.new(ActiveRecord::Base) { self.table_name = "integrations" }

    configuration.find_each do |config|
      next if integration.exists?(account_id: config.account_id, provider: "github")

      integration.create!(
        account_id: config.account_id,
        provider: "github",
        enabled: true,
        credentials: { "webhook_secret" => config.webhook_secret, "api_token" => config.api_token }.compact,
        settings: { "in_review_column_name" => config.in_review_column_name }.compact
      )
    end

    drop_table :github_configurations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
