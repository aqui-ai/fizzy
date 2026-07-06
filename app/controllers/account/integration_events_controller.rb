class Account::IntegrationEventsController < ApplicationController
  before_action :ensure_admin

  def index
    @events = Current.account.integration_events.recent.limit(100)
  end
end
