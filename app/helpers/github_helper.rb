module GithubHelper
  def github_state_tag(label, modifier: label)
    tag.span label, class: class_names("github-state", "github-state--#{modifier}")
  end

  def github_pull_request_state(pull_request)
    return "merged" if pull_request.merged?
    return "draft" if pull_request.open? && pull_request.draft?
    pull_request.state
  end

  def github_review_tag(review_state)
    github_state_tag(review_state.tr("_", " "), modifier: review_state) if review_state.present?
  end

  def github_checks_tag(checks_state)
    github_state_tag("checks: #{checks_state}", modifier: checks_state) if checks_state.present?
  end
end
