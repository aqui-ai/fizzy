require "test_helper"

class DailyUpdateTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @user = users(:david)
  end

  test "one update per user per work day" do
    DailyUpdate.create!(user: @user, work_on: Date.current)

    assert_raises ActiveRecord::RecordInvalid do
      DailyUpdate.create!(user: @user, work_on: Date.current)
    end
  end

  test "account is derived from the user" do
    update = DailyUpdate.create!(user: @user, work_on: Date.current)
    assert_equal @user.account, update.account
  end

  test "for_user finds or initializes today's update" do
    update = DailyUpdate.for_user(@user)
    assert update.new_record?
    assert_equal Date.current, update.work_on
    assert_equal @user, update.user
  end

  test "submitting before the cutoff marks it submitted" do
    update = DailyUpdate.for_user(@user)

    update.submit(now: @user.account.daily_update_cutoff_for(Date.current) - 1.hour)

    assert_predicate update, :submitted?
    assert_not_nil update.submitted_at
  end

  test "submitting after the cutoff marks it late" do
    update = DailyUpdate.for_user(@user)

    update.submit(now: @user.account.daily_update_cutoff_for(Date.current) + 1.hour)

    assert_predicate update, :late?
  end

  test "editing after an on-time submission keeps it submitted" do
    update = DailyUpdate.for_user(@user)

    update.submit(now: @user.account.daily_update_cutoff_for(Date.current) - 1.hour)
    update.submit(now: @user.account.daily_update_cutoff_for(Date.current) + 2.hours)

    assert_predicate update, :submitted?
  end
end
