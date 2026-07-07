# Resolves the token for GitHub REST reads: an App installation token when the
# App is configured, otherwise the personal access token.
module Github::Auth
  def self.token(integration)
    app = Github::App.new(integration)
    app.configured? ? app.installation_token : integration.credential("api_token")
  end
end
