# Records the latest review verdict on a linked PR so the card can show whether
# it's approved or has changes requested.
class Github::PullRequestReviewSync
  def initialize(payload)
    @action = payload["action"]
    @review = payload["review"] || {}
    @pr = payload["pull_request"] || {}
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    if pull_request = repository.pull_requests.find_by(number: @pr["number"])
      pull_request.update!(review_state: review_state)
    end
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    def review_state
      case @action
      when "dismissed"
        nil
      else
        @review["state"].to_s.downcase.presence
      end
    end
end
