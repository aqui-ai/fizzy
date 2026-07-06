module CardsHelper
  def card_article_tag(card, id: dom_id(card, :article), data: {}, **options, &block)
    classes = [
      options.delete(:class),
      ("golden-effect" if card.golden?),
      ("card--postponed" if card.postponed?),
      ("card--active" if card.active?)
    ].compact.join(" ")

    data[:drag_and_drop_top] = true if card.golden? && !card.closed? && !card.postponed?

    tag.article \
      id: id,
      style: "--card-color: #{card.color}; view-transition-name: #{id}",
      class: classes,
      data: data,
      **options,
      &block
  end

  def card_title_tag(card)
    title = [
      card.title,
      "added by #{card.creator.name}",
      "in #{card.board.name}"
    ]
    title << "assigned to #{card.assignees.map(&:name).to_sentence}" if card.assignees.any?
    title.join(" ")
  end

  def card_drafted_or_added(card)
    card.drafted? ? "Drafted" : "Added"
  end

  def card_deadline_label(card, format: :long)
    return unless card.due_on?

    date = format == :short ? card.due_on.strftime("%b %-d") : card.due_on.strftime("%b %-d, %Y")
    [ card_deadline_status(card), date ].join(" ")
  end

  def card_deadline_classes(card)
    class_names(
      "card__deadline",
      "card__deadline--today": card.due_on? && card.due_on == Date.current,
      "card__deadline--soon": card.due_on? && card.due_on.in?(Date.tomorrow..7.days.from_now.to_date),
      "card__deadline--overdue": card.due_on? && card.due_on < Date.current
    )
  end

  def card_deadline_status(card)
    case card.due_on
    when ...Date.current
      "Overdue"
    when Date.current
      "Due today"
    when Date.tomorrow..7.days.from_now.to_date
      "Due soon"
    else
      "Deadline"
    end
  end

  def card_priority_badge(card)
    return unless card.prioritized?

    tag.span card.priority_label, class: card_priority_classes(card)
  end

  def card_priority_classes(card)
    class_names("card__priority", "card__priority--#{card.priority}")
  end

  def card_social_tags(card)
    tag.meta(property: "og:title", content: "#{card.title} | #{card.board.name}") +
    tag.meta(property: "og:description", content: format_excerpt(card&.description, length: 200)) +
    tag.meta(property: "og:image", content: card.image.attached? ? "#{request.base_url}#{url_for(card.image)}" : "#{request.base_url}/opengraph.png") +
    tag.meta(property: "og:url", content: card_url(card))
  end

  def button_to_remove_card_image(card)
    button_to(card_image_path(card), method: :delete, class: "btn", data: { controller: "tooltip", action: "dialog#close" }) do
      icon_tag("trash") + tag.span("Remove background image", class: "for-screen-reader")
    end
  end
end
