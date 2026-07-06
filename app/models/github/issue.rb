class Github::Issue < ApplicationRecord
  belongs_to :account, default: -> { repository.account }
  belongs_to :repository
  belongs_to :board, optional: true
  belongs_to :card, optional: true, touch: true

  has_many :github_comments, class_name: "Github::Comment", foreign_key: :issue_id, dependent: :destroy

  validates :number, uniqueness: { scope: [ :account_id, :repository_id ] }

  def open?
    state == "open"
  end

  def closed?
    state == "closed"
  end
end
