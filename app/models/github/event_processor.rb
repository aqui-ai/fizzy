module Github::EventProcessor
  # Returns true when the event was handled, false when it should be ignored.
  def self.process(event_type, payload)
    case event_type
    when "issues"
      Github::IssueSync.new(payload).process
      true
    when "pull_request"
      Github::PullRequestSync.new(payload).process
      true
    when "issue_comment"
      Github::CommentSync.new(payload).process
      true
    else
      false
    end
  end
end
