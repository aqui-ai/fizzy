class CreateDailyUpdates < ActiveRecord::Migration[8.2]
  def change
    create_table :daily_updates, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :user_id, null: false
      t.date :work_on, null: false
      t.text :completed_yesterday
      t.text :planned_today
      t.text :blockers
      t.datetime :submitted_at
      t.string :status, default: "draft", null: false
      t.timestamps

      t.index [ :account_id, :user_id, :work_on ], unique: true, name: "index_daily_updates_on_account_and_user_and_work_on"
      t.index [ :account_id, :work_on ], name: "index_daily_updates_on_account_id_and_work_on"
    end
  end
end
