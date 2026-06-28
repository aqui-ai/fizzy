class AddDeadlineNotificationTimestampsToCards < ActiveRecord::Migration[8.2]
  def change
    add_column :cards, :due_notified_at, :datetime
    add_column :cards, :overdue_notified_at, :datetime
  end
end
