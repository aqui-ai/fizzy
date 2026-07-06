module User::Teamed
  extend ActiveSupport::Concern

  included do
    has_many :team_memberships, dependent: :destroy
    has_many :teams, through: :team_memberships
    has_many :led_memberships, -> { where(lead: true) }, class_name: "TeamMembership"
    has_many :led_teams, through: :led_memberships, source: :team
  end

  # Whether this user can see other people's accountability data.
  def manages_accountability?
    admin? || led_teams.any?
  end

  # The active users this person is accountable for: everyone for admins/owners,
  # the members of their led teams' subtrees for team leads, otherwise just themselves.
  def accountable_users
    if admin?
      account.users.active
    elsif led_teams.any?
      account.users.active.where(id: managed_user_ids)
    else
      account.users.active.where(id: id)
    end
  end

  private
    def managed_user_ids
      team_ids = led_teams.flat_map(&:self_and_descendant_ids).uniq
      TeamMembership.where(team_id: team_ids).distinct.pluck(:user_id)
    end
end
