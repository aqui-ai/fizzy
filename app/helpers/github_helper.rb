module GithubHelper
  def github_state_tag(state)
    tag.span state, class: class_names("github-state", "github-state--#{state}")
  end

  def github_pull_request_state(pull_request)
    pull_request.merged? ? "merged" : pull_request.state
  end
end
