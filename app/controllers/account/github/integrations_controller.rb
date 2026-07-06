class Account::Github::IntegrationsController < ApplicationController
  before_action :ensure_admin

  def show
    @configuration = configuration
    @repositories = Current.account.github_repositories.order(:full_name)
    @user_links = Current.account.github_user_links.includes(:user).order(:github_login)
    @boards = Current.account.boards.order(:name)
    @users = Current.account.users.active.order(:name)
  end

  def update
    attributes = configuration_params
    attributes.delete(:webhook_secret) if attributes[:webhook_secret].blank?
    configuration.update!(attributes)

    redirect_to account_github_integration_path, notice: "GitHub settings saved"
  end

  private
    def configuration
      Current.account.github_configuration || Current.account.build_github_configuration
    end

    def configuration_params
      params.expect(github_configuration: [ :webhook_secret, :in_review_column_name ])
    end
end
