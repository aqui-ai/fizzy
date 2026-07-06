class Github::UserLink < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :user

  validates :github_login, uniqueness: { scope: :account_id }

  class << self
    def user_for(login)
      find_by(github_login: login)&.user
    end
  end
end
