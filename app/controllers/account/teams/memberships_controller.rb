class Account::Teams::MembershipsController < ApplicationController
  before_action :ensure_admin

  def create
    team.memberships.create!(user_id: membership_params[:user_id], lead: lead?)
    redirect_to account_teams_path, notice: "Member added"
  rescue ActiveRecord::RecordInvalid
    redirect_to account_teams_path, alert: "That person is already on the team"
  end

  def update
    membership.update!(lead: lead?)
    redirect_to account_teams_path
  end

  def destroy
    membership.destroy!
    redirect_to account_teams_path, notice: "Member removed"
  end

  private
    def team
      @team ||= Current.account.teams.find(params[:team_id])
    end

    def membership
      @membership ||= team.memberships.find(params[:id])
    end

    def lead?
      membership_params[:lead] == "1"
    end

    def membership_params
      params.expect(team_membership: [ :user_id, :lead ])
    end
end
