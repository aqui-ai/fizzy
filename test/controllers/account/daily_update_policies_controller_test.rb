require "test_helper"

class Account::DailyUpdatePoliciesControllerTest < ActionDispatch::IntegrationTest
  test "admins can update the policy" do
    sign_in_as :kevin

    patch account_daily_update_policy_path, params: { account: { daily_update_cutoff_hour: 15, daily_update_exclude_weekends: "0" } }

    assert_redirected_to account_settings_path
    assert_equal 15, accounts("37s").reload.daily_update_cutoff_hour
    assert_not accounts("37s").daily_update_exclude_weekends?
  end

  test "members cannot update the policy" do
    sign_in_as :david

    patch account_daily_update_policy_path, params: { account: { daily_update_cutoff_hour: 8 } }

    assert_response :forbidden
  end
end
