require "test_helper"

class Card::DeadlineTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @card = cards(:logo)
    @card.update!(due_on: Date.current)
    Notification.where(card: @card).destroy_all
    @card.events.where(action: [ "card_due", "card_overdue" ]).destroy_all
  end

  test "notify_deadlines_due notifies assignees when a card is due today" do
    assert_difference -> { Notification.where(card: @card).count }, +2 do
      Card.notify_deadlines_due
    end

    notifications = Notification.where(card: @card)
    assert_equal @card.assignees.sort_by(&:id), notifications.map(&:user).sort_by(&:id)
    assert_equal [ "card_due" ], notifications.map { |notification| notification.source.action }.uniq
    assert_predicate @card.reload, :due_notified_at?
  end

  test "notify_deadlines_due notifies assignees when a card is overdue" do
    @card.update!(due_on: Date.yesterday)

    assert_difference -> { Notification.where(card: @card).count }, +2 do
      Card.notify_deadlines_due
    end

    notifications = Notification.where(card: @card)
    assert_equal @card.assignees.sort_by(&:id), notifications.map(&:user).sort_by(&:id)
    assert_equal [ "card_overdue" ], notifications.map { |notification| notification.source.action }.uniq
    assert_predicate @card.reload, :overdue_notified_at?
  end

  test "notify_deadlines_due falls back to watchers when a card has no assignees" do
    @card.assignments.destroy_all
    @card.watches.destroy_all
    @card.watch_by users(:david)
    @card.watch_by users(:jz)

    assert_difference -> { Notification.where(card: @card).count }, +2 do
      Card.notify_deadlines_due
    end

    assert_equal [ users(:david), users(:jz) ].sort_by(&:id), Notification.where(card: @card).map(&:user).sort_by(&:id)
  end

  test "notify_deadlines_due does not notify due cards twice" do
    assert_difference -> { Notification.where(card: @card).count }, +2 do
      Card.notify_deadlines_due
    end

    assert_no_difference -> { Notification.where(card: @card).count } do
      Card.notify_deadlines_due
    end
  end

  test "notify_deadlines_due does not notify overdue cards twice" do
    @card.update!(due_on: Date.yesterday)

    assert_difference -> { Notification.where(card: @card).count }, +2 do
      Card.notify_deadlines_due
    end

    assert_no_difference -> { Notification.where(card: @card).count } do
      Card.notify_deadlines_due
    end
  end

  test "notify_deadlines_due ignores closed cards" do
    @card.close

    assert_no_difference -> { Notification.where(card: @card).count } do
      Card.notify_deadlines_due
    end
  end

  test "notify_deadlines_due ignores postponed cards" do
    @card.postpone

    assert_no_difference -> { Notification.where(card: @card).count } do
      Card.notify_deadlines_due
    end
  end

  test "changing deadline resets notification timestamps" do
    @card.update!(due_notified_at: Time.current, overdue_notified_at: Time.current)

    @card.update!(due_on: Date.tomorrow)

    assert_nil @card.due_notified_at
    assert_nil @card.overdue_notified_at
  end
end
