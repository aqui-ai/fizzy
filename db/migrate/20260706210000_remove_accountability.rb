class RemoveAccountability < ActiveRecord::Migration[8.2]
  def up
    drop_table :daily_updates, if_exists: true
    drop_table :report_snapshots, if_exists: true
    remove_column :accounts, :daily_update_cutoff_hour, if_exists: true
    remove_column :accounts, :daily_update_exclude_weekends, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
