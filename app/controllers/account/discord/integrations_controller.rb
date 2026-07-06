class Account::Discord::IntegrationsController < ApplicationController
  before_action :ensure_admin

  def show
    @integration = discord_integration
  end

  def update
    integration = discord_integration
    integration.credentials = credentials_for(integration)
    integration.enabled = discord_params[:enabled] == "1"
    integration.save!

    redirect_to account_discord_integration_path, notice: "Discord settings saved"
  end

  private
    def discord_integration
      Current.account.integrations.find_or_initialize_by(provider: "discord")
    end

    def credentials_for(integration)
      credentials = (integration.credentials || {}).dup
      credentials["webhook_url"] = discord_params[:webhook_url] if discord_params[:webhook_url].present?
      credentials
    end

    def discord_params
      @discord_params ||= params.expect(discord: [ :webhook_url, :enabled ])
    end
end
