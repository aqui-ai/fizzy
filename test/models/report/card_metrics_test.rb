require "test_helper"

class Report::CardMetricsTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:kevin)
    @window = 7.days.ago..1.day.from_now
  end

  test "open counts newly created active cards" do
    assert_difference -> { metrics.open }, +1 do
      create_card
    end
  end

  test "done counts closed cards, not open ones" do
    card = create_card

    assert_difference -> { metrics.done }, +1 do
      card.close
    end
  end

  test "not_now counts postponed cards" do
    card = create_card

    assert_difference -> { metrics.not_now }, +1 do
      card.postpone
    end
  end

  test "overdue counts active cards past their deadline" do
    assert_difference -> { metrics.overdue }, +1 do
      create_card due_on: Date.yesterday
    end
  end

  test "due_this_week counts active cards due within the week" do
    assert_difference -> { metrics.due_this_week }, +1 do
      create_card due_on: Date.current
    end
  end

  test "unassigned counts active cards without assignees" do
    assert_difference -> { metrics.unassigned }, +1 do
      create_card
    end
  end

  test "closed_in_window only counts cards closed inside the window" do
    card = create_card

    assert_difference -> { metrics.closed_in_window }, +1 do
      card.close
    end

    assert_difference -> { metrics.closed_in_window }, -1 do
      card.closure.update!(created_at: 2.weeks.ago)
    end
  end

  test "respects board access through accessible_cards" do
    secret = boards(:private).cards.create!(title: "Secret", status: :published, last_active_at: Time.current)
    secret.close

    assert_includes closed_titles(users(:kevin)), "Secret"
    assert_not_includes closed_titles(users(:david)), "Secret"
  end

  private
    def metrics(user: users(:kevin))
      Report::CardMetrics.new(cards: user.accessible_cards.published, window: @window)
    end

    def create_card(**attributes)
      boards(:writebook).cards.create!({ title: "Card", status: :published, last_active_at: Time.current }.merge(attributes))
    end

    def closed_titles(user)
      user.accessible_cards.published.closed.pluck(:title)
    end
end
