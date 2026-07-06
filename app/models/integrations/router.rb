module Integrations::Router
  def self.dispatch(event)
    case event.provider
    when "github" then Github::EventProcessor.process(event.event_type, event.payload)
    else false
    end
  end
end
