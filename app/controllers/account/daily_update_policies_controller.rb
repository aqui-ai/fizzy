class Account::DailyUpdatePoliciesController < ApplicationController
  before_action :ensure_admin

  def update
    Current.account.update!(daily_update_params)

    respond_to do |format|
      format.html { redirect_to account_settings_path, notice: "Daily update settings saved" }
      format.json { render "account/settings/show", status: :ok }
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  private
    def daily_update_params
      params.expect(account: [ :daily_update_cutoff_hour, :daily_update_exclude_weekends ])
    end
end
