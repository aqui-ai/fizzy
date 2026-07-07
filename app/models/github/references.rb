# Extracts card-reference tokens ("CORE-54") from PR text (title, body, branch).
# A token is treated as "automate" (drives status transitions) unless it is
# preceded by a non-closing keyword like "ref" or "related to", which links
# without moving the card. Closing keywords and bare mentions both automate;
# the distinction between them is a Phase 2 refinement.
class Github::References
  Reference = Data.define(:token, :automate)

  NON_CLOSING_KEYWORDS = [
    "references", "reference", "refs", "ref",
    "part of", "relates to", "related to", "contributes to", "towards", "toward"
  ].freeze

  TOKEN = /\b([A-Za-z][A-Za-z0-9]+-\d+)\b/
  NON_CLOSING = /\b(?:#{NON_CLOSING_KEYWORDS.map { |keyword| keyword.gsub(" ", '\s+') }.join("|")})\s+([A-Za-z][A-Za-z0-9]+-\d+)\b/i

  def self.extract(text)
    new(text).extract
  end

  def initialize(text)
    @text = text.to_s
  end

  def extract
    tokens.map { |token| Reference.new(token, !link_only.include?(token)) }
  end

  private
    def tokens
      @text.scan(TOKEN).flatten.map(&:upcase).uniq
    end

    def link_only
      @text.scan(NON_CLOSING).flatten.map(&:upcase).to_set
    end
end
