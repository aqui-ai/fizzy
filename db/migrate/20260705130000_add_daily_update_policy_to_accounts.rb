class AddDailyUpdatePolicyToAccounts < ActiveRecord::Migration[8.2]
  def change
    add_column :accounts, :daily_update_cutoff_hour, :integer, default: 17, null: false
    add_column :accounts, :daily_update_exclude_weekends, :boolean, default: true, null: false
  end
end
