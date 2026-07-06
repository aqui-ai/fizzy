class CreateReportSnapshots < ActiveRecord::Migration[8.2]
  def change
    create_table :report_snapshots, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :board_id
      t.date :snapshot_on, null: false
      t.json :metrics
      t.timestamps

      t.index [ :account_id, :board_id, :snapshot_on ], unique: true, name: "index_report_snapshots_on_account_and_board_and_date"
      t.index [ :account_id, :snapshot_on ], name: "index_report_snapshots_on_account_id_and_snapshot_on"
    end
  end
end
