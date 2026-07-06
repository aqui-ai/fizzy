class Github::CommentSync
  def initialize(payload)
    @action = payload["action"]
    @comment = payload["comment"] || {}
    @issue_data = payload["issue"] || {}
    @repo = payload["repository"] || {}
  end

  def process
    return unless repository

    case @action
    when "created" then create
    when "edited"  then edit
    when "deleted" then delete
    end
  end

  private
    def repository
      @repository ||= Current.account.github_repositories.register(@repo)
    end

    def issue
      @issue ||= repository.issues.find_by(number: @issue_data["number"])
    end

    def create
      return if issue&.card.nil? || mirror

      comment = issue.card.comments.create!(body: mirrored_body, creator: author)
      Current.account.github_comments.create!(github_id: @comment["id"], issue: issue, comment: comment)
    end

    def edit
      mirror&.comment&.update!(body: mirrored_body)
    end

    def delete
      if record = mirror
        record.comment.destroy
        record.destroy
      end
    end

    def mirror
      @mirror ||= Current.account.github_comments.find_by(github_id: @comment["id"])
    end

    def mirrored_body
      source = ERB::Util.html_escape(@comment["html_url"])
      %(#{ERB::Util.html_escape(@comment["body"])}<div class="txt-subtle txt-small">— <a href="#{source}">via GitHub</a></div>)
    end

    def author
      Current.account.github_user_links.user_for(@comment.dig("user", "login")) || Current.account.system_user
    end
end
