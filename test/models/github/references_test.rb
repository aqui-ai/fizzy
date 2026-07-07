require "test_helper"

class Github::ReferencesTest < ActiveSupport::TestCase
  test "extracts an uppercased token" do
    references = Github::References.extract("Implement CORE-54 today")

    assert_equal [ "CORE-54" ], references.map(&:token)
  end

  test "normalizes a lowercase branch token to uppercase" do
    references = Github::References.extract("melvin/core-54-fix-otp")

    assert_equal [ "CORE-54" ], references.map(&:token)
    assert references.first.automate
  end

  test "a bare mention automates" do
    assert Github::References.extract("CORE-54").first.automate
  end

  test "a closing keyword automates" do
    assert Github::References.extract("Fixes CORE-54").first.automate
  end

  test "a non-closing keyword links without automating" do
    reference = Github::References.extract("Related to CORE-54").first

    assert_equal "CORE-54", reference.token
    assert_not reference.automate
  end

  test "recognizes multi-word non-closing keywords" do
    assert_not Github::References.extract("part of CORE-54").first.automate
    assert_not Github::References.extract("contributes to CORE-54").first.automate
  end

  test "dedupes repeated tokens" do
    assert_equal [ "CORE-54" ], Github::References.extract("CORE-54 and again CORE-54").map(&:token)
  end

  test "extracts multiple distinct tokens" do
    tokens = Github::References.extract("Fixes CORE-54 and AGENT-3").map(&:token)

    assert_equal %w[ CORE-54 AGENT-3 ], tokens
  end

  test "ignores text without a token" do
    assert_empty Github::References.extract("no references here")
  end
end
