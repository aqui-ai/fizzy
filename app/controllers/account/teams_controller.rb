class Account::TeamsController < ApplicationController
  before_action :ensure_admin

  def index
    @teams = Current.account.teams.roots.order(:name)
    @all_teams = Current.account.teams.order(:name)
    @users = Current.account.users.active.order(:name)
  end

  def create
    Current.account.teams.create!(team_params)
    redirect_to account_teams_path, notice: "Team created"
  end

  def destroy
    Current.account.teams.find(params[:id]).destroy!
    redirect_to account_teams_path, notice: "Team removed"
  end

  private
    def team_params
      params.expect(team: [ :name, :parent_id ])
    end
end
