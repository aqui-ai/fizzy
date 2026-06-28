require "test_helper"

class CardsHelperTest < ActionView::TestCase
  test "card priority badge" do
    card = cards(:logo)

    card.priority = "none"
    assert_nil card_priority_badge(card)

    card.priority = "urgent"
    badge = card_priority_badge(card)

    assert_includes badge, "Urgent"
    assert_includes badge, "card__priority--urgent"
  end

  test "card deadline labels" do
    travel_to Time.zone.local(2026, 6, 15) do
      card = cards(:logo)

      card.due_on = Date.yesterday
      assert_equal "Overdue Jun 14, 2026", card_deadline_label(card)

      card.due_on = Date.current
      assert_equal "Due today Jun 15, 2026", card_deadline_label(card)

      card.due_on = Date.tomorrow
      assert_equal "Due soon Jun 16, 2026", card_deadline_label(card)

      card.due_on = 2.weeks.from_now.to_date
      assert_equal "Deadline Jun 29, 2026", card_deadline_label(card)
    end
  end

  test "card deadline classes" do
    travel_to Time.zone.local(2026, 6, 15) do
      card = cards(:logo)

      card.due_on = Date.current
      assert_includes card_deadline_classes(card), "card__deadline--today"

      card.due_on = Date.tomorrow
      assert_includes card_deadline_classes(card), "card__deadline--soon"

      card.due_on = Date.yesterday
      assert_includes card_deadline_classes(card), "card__deadline--overdue"
    end
  end
end
