require "test_helper"

class ExternalLinkTest < ActiveSupport::TestCase
  setup do
    Current.account = accounts("37s")
    @card = cards(:logo)
  end

  test "record creates a link and derives the account from the linkable" do
    link = ExternalLink.record(linkable: @card, provider: "github", external_type: "issue", external_id: "42", external_url: "https://x/42")

    assert_equal @card, link.linkable
    assert_equal accounts("37s"), link.account
  end

  test "record is idempotent for the same linkable, provider and type" do
    ExternalLink.record(linkable: @card, provider: "github", external_type: "issue", external_id: "42")

    assert_no_difference -> { ExternalLink.count } do
      ExternalLink.record(linkable: @card, provider: "github", external_type: "issue", external_id: "43")
    end
    assert_equal "43", @card.reload && ExternalLink.find_by(linkable: @card, external_type: "issue").external_id
  end
end
