class Github::Comment < ApplicationRecord
  belongs_to :account, default: -> { issue.account }
  belongs_to :issue
  belongs_to :comment, class_name: "::Comment"

  validates :github_id, uniqueness: { scope: :account_id }
end
