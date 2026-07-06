class Account::Github::BackfillsController < ApplicationController
  before_action :ensure_admin

  def create
    repository = Current.account.github_repositories.find(params[:repository_id])
    Github::BackfillRepositoryJob.perform_later(repository)

    redirect_to account_github_integration_path, notice: "Backfilling #{repository.full_name}…"
  end
end
