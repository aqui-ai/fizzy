# Records CI status on linked PRs from check_suite and legacy status events.
class Github::ChecksSync
  def initialize(payload)
    @suite = payload["check_suite"]
    @status = payload["state"] if payload.key?("state")
    @status_branches = payload["branches"]
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    if state = @suite ? suite_state : status_state
      target_pull_requests.each { |pull_request| pull_request.update!(checks_state: state) }
    end
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    def suite_state
      return unless @suite["status"] == "completed"

      case @suite["conclusion"]
      when "success" then "success"
      when "failure", "timed_out", "cancelled", "action_required" then "failure"
      else "neutral"
      end
    end

    def status_state
      case @status
      when "success" then "success"
      when "failure", "error" then "failure"
      when "pending" then "pending"
      end
    end

    def target_pull_requests
      if @suite
        numbers = Array(@suite["pull_requests"]).filter_map { |pull_request| pull_request["number"] }
        repository.pull_requests.where(number: numbers)
      else
        branches = Array(@status_branches).filter_map { |branch| branch["name"] }
        repository.pull_requests.where(head_ref: branches)
      end
    end
end
