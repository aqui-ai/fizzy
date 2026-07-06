class Team < ApplicationRecord
  belongs_to :account
  belongs_to :parent, class_name: "Team", optional: true

  has_many :children, class_name: "Team", foreign_key: :parent_id, dependent: :destroy
  has_many :memberships, class_name: "TeamMembership", dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :leads, -> { where(team_memberships: { lead: true }) }, through: :memberships, source: :user

  validates :name, presence: true

  scope :roots, -> { where(parent_id: nil) }

  def self_and_descendant_ids
    children.reduce([ id ]) { |ids, child| ids + child.self_and_descendant_ids }
  end

  def ancestors
    parent ? [ parent ] + parent.ancestors : []
  end
end
