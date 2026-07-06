class Account::Github::UserLinksController < ApplicationController
  before_action :ensure_admin

  def create
    Current.account.github_user_links.create!(user_link_params)
    redirect_to account_github_integration_path, notice: "GitHub user linked"
  rescue ActiveRecord::RecordInvalid
    redirect_to account_github_integration_path, alert: "Could not link that GitHub user"
  end

  def destroy
    Current.account.github_user_links.find(params[:id]).destroy!
    redirect_to account_github_integration_path, notice: "GitHub user unlinked"
  end

  private
    def user_link_params
      params.expect(github_user_link: [ :github_login, :user_id ])
    end
end
