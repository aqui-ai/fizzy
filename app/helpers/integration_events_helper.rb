module IntegrationEventsHelper
  def integration_event_status_tag(event)
    tag.span event.status, class: class_names("integration-event__status", "integration-event__status--#{event.status}")
  end
end
