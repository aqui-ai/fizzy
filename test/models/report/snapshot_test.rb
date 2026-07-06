require "test_helper"

class Report::SnapshotTest < ActiveSupport::TestCase
  setup do
    @account = accounts("37s")
  end

  test "capture_for stores an account-wide snapshot with metrics" do
    Report::Snapshot.capture_for(@account)

    snapshot = @account.report_snapshots.account_wide.find_by(snapshot_on: Date.current)
    assert_not_nil snapshot
    assert_equal @account.cards.published.active.count, snapshot.metric("open")
    assert_equal @account.cards.published.overdue.active.count, snapshot.metric("overdue")
  end

  test "capture_for is idempotent for the same day" do
    Report::Snapshot.capture_for(@account)

    assert_no_difference -> { Report::Snapshot.count } do
      Report::Snapshot.capture_for(@account)
    end
  end

  test "capture_all snapshots every account" do
    assert_difference -> { Report::Snapshot.account_wide.count }, Account.count do
      Report::Snapshot.capture_all
    end
  end

  test "metric defaults to zero for unknown keys" do
    snapshot = @account.report_snapshots.create!(snapshot_on: Date.current, metrics: {})
    assert_equal 0, snapshot.metric("open")
  end
end
