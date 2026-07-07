class Account::Github::IntegrationsController < ApplicationController
  before_action :ensure_admin

  def show
    @integration = Current.account.github_integration
    @repositories = Current.account.github_repositories.order(:full_name)
    @user_links = Current.account.github_user_links.includes(:user).order(:github_login)
    @boards = Current.account.boards.order(:name)
    @users = Current.account.users.active.order(:name)
  end

  def update
    integration = Current.account.github_integration
    integration.credentials = credentials_for(integration)
    integration.settings = {
      "in_progress_column_name" => github_params[:in_progress_column_name],
      "in_review_column_name" => github_params[:in_review_column_name]
    }
    integration.save!

    redirect_to account_github_integration_path, notice: "GitHub settings saved"
  end

  private
    # Blank secret/token fields leave the stored values untouched.
    def credentials_for(integration)
      credentials = (integration.credentials || {}).dup
      %i[ webhook_secret api_token app_id app_installation_id app_private_key ].each do |key|
        credentials[key.to_s] = github_params[key] if github_params[key].present?
      end
      credentials
    end

    def github_params
      @github_params ||= params.expect(github: [ :webhook_secret, :api_token, :app_id, :app_installation_id, :app_private_key, :in_progress_column_name, :in_review_column_name ])
    end
end
