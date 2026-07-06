require "test_helper"

class DailyUpdateRemindersTest < ActiveSupport::TestCase
  setup do
    travel_to Time.zone.local(2026, 7, 6, 12, 0) # a Monday, before the 17:00 cutoff
    ActionMailer::Base.deliveries.clear
  end

  test "mark_missing_due skips weekends when the account excludes them" do
    accounts("37s").update!(daily_update_exclude_weekends: true)

    travel_to Time.zone.local(2026, 7, 4, 18, 0) do # a Saturday
      assert_no_difference -> { DailyUpdate.count } do
        DailyUpdate.mark_missing_due
      end
    end
  end

  test "mark_missing_due marks active users without a submission as missing" do
    DailyUpdate.mark_missing_due

    assert_predicate today_update(:david), :missing?
  end

  test "mark_missing_due ignores users who already submitted" do
    submit_for :david

    DailyUpdate.mark_missing_due

    assert_not today_update(:david).missing?
  end

  test "mark_missing_due ignores system and inactive users" do
    DailyUpdate.mark_missing_due

    assert_empty DailyUpdate.where(user: users(:system))
  end

  test "mark_missing_due is idempotent" do
    DailyUpdate.mark_missing_due

    assert_no_difference -> { DailyUpdate.count } do
      DailyUpdate.mark_missing_due
    end
  end

  test "remind_due emails active users who have not submitted" do
    DailyUpdate.remind_due

    assert_includes recipients, users(:david).identity.email_address
  end

  test "remind_due skips users who already submitted" do
    submit_for :david

    DailyUpdate.remind_due

    assert_not_includes recipients, users(:david).identity.email_address
  end

  test "notify_managers_of_missing_updates emails admins with the missing list" do
    DailyUpdate.mark_missing_due
    ActionMailer::Base.deliveries.clear

    DailyUpdate.notify_managers_of_missing_updates

    assert_includes recipients, users(:kevin).identity.email_address
    assert_includes recipients, users(:jason).identity.email_address
  end

  private
    def today_update(user)
      users(user).daily_updates.for_date(Date.current).first
    end

    def submit_for(user)
      with_current_user(user) { DailyUpdate.for_user(users(user)).submit }
    end

    def recipients
      ActionMailer::Base.deliveries.flat_map(&:to)
    end
end
