class ChangeIntegrationCredentialsToText < ActiveRecord::Migration[8.2]
  # Active Record encryption stores ciphertext strings, which a JSON column
  # rejects on MySQL, so credentials moves to a text column + JSON serializer.
  def up
    change_column :integrations, :credentials, :text
  end

  def down
    change_column :integrations, :credentials, :json
  end
end
