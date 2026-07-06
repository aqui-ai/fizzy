require "test_helper"

class DailyUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :david
  end

  test "show renders today's update form" do
    get daily_update_path
    assert_response :success
  end

  test "history lists the user's updates" do
    get daily_updates_path
    assert_response :success
  end

  test "submitting creates the current user's update for today" do
    assert_difference -> { users(:david).daily_updates.count }, +1 do
      patch daily_update_path, params: { commit: "submit", daily_update: { planned_today: "Ship reports" } }
    end

    update = users(:david).daily_updates.for_date(Date.current).first
    assert_equal "Ship reports", update.planned_today
    assert_not update.draft?
  end

  test "saving a draft keeps it as a draft" do
    patch daily_update_path, params: { commit: "draft", daily_update: { planned_today: "Rough notes" } }

    update = users(:david).daily_updates.for_date(Date.current).first
    assert_predicate update, :draft?
    assert_equal "Rough notes", update.planned_today
  end

  test "submitting after saving a draft marks it submitted" do
    patch daily_update_path, params: { commit: "draft", daily_update: { planned_today: "Draft" } }

    assert_no_difference -> { users(:david).daily_updates.count } do
      patch daily_update_path, params: { commit: "submit", daily_update: { planned_today: "Final" } }
    end

    update = users(:david).daily_updates.for_date(Date.current).first
    assert_not update.draft?
    assert_equal "Final", update.planned_today
  end
end
