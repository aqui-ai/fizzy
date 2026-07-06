class Account::Github::RepositoriesController < ApplicationController
  before_action :ensure_admin

  def update
    repository = Current.account.github_repositories.find(params[:id])
    repository.update!(repository_params)

    redirect_to account_github_integration_path, notice: "Repository updated"
  end

  private
    def repository_params
      params.expect(github_repository: [ :board_id, :active ])
    end
end
