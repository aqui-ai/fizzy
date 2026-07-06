require "test_helper"

class Account::DailyUpdatableTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
  end

  test "cutoff_for uses the configured hour" do
    @account.update!(daily_update_cutoff_hour: 15)

    assert_equal 15, @account.daily_update_cutoff_for(Date.current).hour
  end

  test "workday? excludes weekends when configured" do
    @account.update!(daily_update_exclude_weekends: true)

    assert @account.daily_update_workday?(Date.new(2026, 7, 6))     # Monday
    assert_not @account.daily_update_workday?(Date.new(2026, 7, 5)) # Sunday
  end

  test "workday? includes weekends when not excluded" do
    @account.update!(daily_update_exclude_weekends: false)

    assert @account.daily_update_workday?(Date.new(2026, 7, 5))
  end

  test "cutoff hour must be within range" do
    @account.daily_update_cutoff_hour = 99

    assert_not @account.valid?
  end
end
