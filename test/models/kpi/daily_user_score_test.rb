require "test_helper"

class Kpi::DailyUserScoreTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
    @user = users(:david)
    @user.assignments.destroy_all
  end

  test "compliance rewards an on-time submission" do
    DailyUpdate.for_user(@user).submit(now: @user.account.daily_update_cutoff_for(Date.current) - 1.hour)

    assert_equal 40, points_for("Daily update submitted on time")
  end

  test "compliance rewards a late submission less" do
    DailyUpdate.for_user(@user).submit(now: @user.account.daily_update_cutoff_for(Date.current) + 1.hour)

    assert_equal 25, points_for("Daily update submitted late")
  end

  test "compliance is zero when the update is missing" do
    assert_equal 0, points_for("Daily update missing")
  end

  test "deadline health rewards no overdue assigned cards" do
    assert_equal 20, points_for("No overdue assigned cards")
  end

  test "deadline health is zero with an overdue assigned card" do
    assign overdue_card

    assert_equal 0, points_for(/overdue assigned/)
  end

  test "completion rewards cards closed today" do
    card = assign(create_card)
    card.close

    assert_operator points_for(/closed today/), :>, 0
  end

  private
    def score
      Kpi::DailyUserScore.new(user: @user)
    end

    def points_for(matcher)
      reason = score.reasons.find do |r|
        matcher.is_a?(Regexp) ? r.label.match?(matcher) : r.label == matcher
      end
      reason&.points
    end

    def create_card(**attributes)
      boards(:writebook).cards.create!({ title: "Card", status: :published, last_active_at: Time.current }.merge(attributes))
    end

    def overdue_card
      create_card(due_on: Date.yesterday)
    end

    def assign(card)
      card.assignments.create!(assignee: @user, assigner: @user)
      card
    end
end
