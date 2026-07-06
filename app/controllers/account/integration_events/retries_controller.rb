class Account::IntegrationEvents::RetriesController < ApplicationController
  before_action :ensure_admin

  def create
    event = Current.account.integration_events.find(params[:integration_event_id])
    event.update!(status: :pending)
    Integrations::ProcessEventJob.perform_later(event)

    redirect_to account_integration_events_path, notice: "Retrying event…"
  end
end
