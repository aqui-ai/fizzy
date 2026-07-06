class Reports::TrendsController < ApplicationController
  before_action :ensure_admin

  def show
    @snapshots = Current.account.report_snapshots.account_wide.chronologically.last(30)
  end
end
