class Reports::DailyPerformancesController < ApplicationController
  before_action :ensure_manager

  def show
    @date = Date.current
    @users = Current.user.accountable_users.order(:name)
    @updates = Current.account.daily_updates.for_date(@date).index_by(&:user_id)
    @scores = @users.index_with { |user| Kpi::DailyUserScore.new(user: user, date: @date) }

    @submitted = @users.select { |user| @updates[user.id]&.submitted? }
    @late = @users.select { |user| @updates[user.id]&.late? }
    @missing_count = @users.size - @submitted.size - @late.size
  end

  private
    def ensure_manager
      head :forbidden unless Current.user.manages_accountability?
    end
end
