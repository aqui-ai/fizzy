require "test_helper"

class DailyUpdatesReminderBannerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :david
  end

  test "shows a due banner before the cutoff when not submitted" do
    travel_to Time.zone.local(2026, 7, 6, 9, 0) do
      get daily_update_path
      assert_match "Your daily update is due today", @response.body
    end
  end

  test "shows a missing banner after the cutoff when not submitted" do
    travel_to Time.zone.local(2026, 7, 6, 18, 0) do
      get daily_update_path
      assert_match "Your daily update is missing", @response.body
    end
  end

  test "hides the banner once submitted" do
    travel_to Time.zone.local(2026, 7, 6, 9, 0) do
      patch daily_update_path, params: { commit: "submit", daily_update: { planned_today: "Ship it" } }
      get daily_update_path
      assert_no_match "daily-update-banner", @response.body
    end
  end

  test "hides the banner on excluded weekends" do
    accounts("37s").update!(daily_update_exclude_weekends: true)

    travel_to Time.zone.local(2026, 7, 5, 9, 0) do # Sunday
      get daily_update_path
      assert_no_match "daily-update-banner", @response.body
    end
  end
end
