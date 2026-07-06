class Github::Backfill
  def initialize(repository)
    @repository = repository
    @token = Current.account.github_integration.credential("api_token")
  end

  def run
    return unless @repository.syncing? && @token.present?

    client.issues(@repository.full_name).each { |data| import_issue(data) }
    client.pull_requests(@repository.full_name).each { |data| import_pull_request(data) }
  end

  private
    def client
      @client ||= Github::Client.new(@token)
    end

    def import_issue(data)
      Github::IssueSync.new("action" => "opened", "issue" => data, "repository" => repository_payload).process

      if data["state"] == "closed"
        @repository.issues.find_by(number: data["number"])&.card&.close
      end
    end

    def import_pull_request(data)
      action = data["merged_at"].present? ? "closed" : "opened"
      Github::PullRequestSync.new("action" => action, "pull_request" => pull_request_payload(data), "repository" => repository_payload).process
    end

    def pull_request_payload(data)
      data.merge("merged" => data["merged_at"].present?)
    end

    def repository_payload
      { "id" => @repository.github_id, "full_name" => @repository.full_name, "name" => @repository.name }
    end
end
