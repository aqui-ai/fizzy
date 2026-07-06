class DailyUpdatesController < ApplicationController
  def index
    @daily_updates = Current.user.daily_updates.order(work_on: :desc).limit(60)
  end

  def show
    @daily_update = DailyUpdate.for_user(Current.user)
  end

  def update
    @daily_update = DailyUpdate.for_user(Current.user)
    @daily_update.assign_attributes(daily_update_params)

    if submitting?
      @daily_update.submit
      redirect_to daily_update_path, notice: "Daily update submitted"
    else
      @daily_update.save_draft
      redirect_to daily_update_path, notice: "Draft saved"
    end
  end

  private
    def submitting?
      params[:commit] == "submit"
    end

    def daily_update_params
      params.expect(daily_update: [ :completed_yesterday, :planned_today, :blockers ])
    end
end
