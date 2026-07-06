class Reports::DailyPerformancesController < ApplicationController
  before_action :ensure_admin

  def show
    @date = Date.current
    @users = Current.account.users.active.order(:name)
    @updates = Current.account.daily_updates.for_date(@date).index_by(&:user_id)
    @scores = @users.index_with { |user| Kpi::DailyUserScore.new(user: user, date: @date) }

    @submitted = @updates.values.select(&:submitted?)
    @late = @updates.values.select(&:late?)
    @missing_count = @users.size - @submitted.size - @late.size
  end
end
