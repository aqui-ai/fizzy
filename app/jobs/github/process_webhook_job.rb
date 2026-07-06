class Github::ProcessWebhookJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(event:, delivery: nil, payload: {})
    Current.user = Current.account.system_user

    case event
    when "issues"       then Github::IssueSync.new(payload).process
    when "pull_request" then Github::PullRequestSync.new(payload).process
    end
  end
end
