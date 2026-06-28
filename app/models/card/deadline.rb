module Card::Deadline
  extend ActiveSupport::Concern

  included do
    before_save :reset_deadline_notifications, if: :will_save_change_to_due_on?
  end

  class_methods do
    def notify_deadlines_due(as_of: Date.current)
      active.with_deadline.where(due_notified_at: nil, due_on: as_of).find_each do |card|
        card.notify_deadline(:due, as_of:)
      end

      active.with_deadline.where(overdue_notified_at: nil, due_on: ...as_of).find_each do |card|
        card.notify_deadline(:overdue, as_of:)
      end
    end
  end

  def notify_deadline(state, as_of: Date.current)
    return unless published? && active? && due_on?
    return if state == :due && (due_on != as_of || due_notified_at?)
    return if state == :overdue && (due_on >= as_of || overdue_notified_at?)

    transaction do
      event = deadline_event_for(state)
      deadline_recipients.each { |recipient| create_deadline_notification(event, recipient) }
      touch(state == :due ? :due_notified_at : :overdue_notified_at)
    end
  end

  private
    def reset_deadline_notifications
      self.due_notified_at = nil
      self.overdue_notified_at = nil
    end

    def deadline_event_for(state)
      events.create!(
        action: "card_#{state}",
        board: board,
        creator: account.system_user,
        particulars: { due_on: due_on.iso8601 }
      )
    end

    def deadline_recipients
      assignees.presence || watchers
    end

    def create_deadline_notification(event, recipient)
      notification = Notification.create_or_find_by!(user: recipient, card: self) do |n|
        n.source = event
        n.creator = event.creator
        n.unread_count = 1
      end

      unless notification.previously_new_record?
        notification.source_type_will_change!
        notification.update!(source: event, creator: event.creator, read_at: nil, unread_count: notification.unread_count + 1)
      end
    end
end
