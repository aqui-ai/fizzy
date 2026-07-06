class Github::PullRequest < ApplicationRecord
  belongs_to :account, default: -> { repository.account }
  belongs_to :repository
  belongs_to :board, optional: true
  belongs_to :card, optional: true

  validates :number, uniqueness: { scope: [ :account_id, :repository_id ] }

  def merged?
    merged
  end
end
