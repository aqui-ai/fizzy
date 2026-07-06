class CreateIntegrationPlatform < ActiveRecord::Migration[8.2]
  def change
    create_table :integrations, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :provider, null: false
      t.string :name
      t.boolean :enabled, default: true, null: false
      t.json :settings
      t.json :credentials
      t.timestamps

      t.index [ :account_id, :provider ], unique: true, name: "index_integrations_on_account_and_provider"
    end

    create_table :integration_events, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :integration_id
      t.string :provider, null: false
      t.string :external_id
      t.string :event_type
      t.json :payload
      t.string :status, default: "pending", null: false
      t.datetime :received_at
      t.datetime :processed_at
      t.datetime :failed_at
      t.text :error_message
      t.timestamps

      t.index [ :account_id, :provider, :external_id ], unique: true, name: "index_integration_events_on_account_provider_external"
      t.index [ :account_id, :status ], name: "index_integration_events_on_account_and_status"
    end

    create_table :external_links, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :linkable_type, null: false
      t.uuid :linkable_id, null: false
      t.string :provider, null: false
      t.string :external_type
      t.string :external_id
      t.string :external_url
      t.json :metadata
      t.timestamps

      t.index [ :account_id, :provider, :external_type, :external_id ], name: "index_external_links_on_account_provider_and_external"
      t.index [ :linkable_type, :linkable_id ], name: "index_external_links_on_linkable"
    end
  end
end
