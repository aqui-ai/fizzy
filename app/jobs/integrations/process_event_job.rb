class Integrations::ProcessEventJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(event)
    Current.user ||= event.account.system_user
    event.process_now
  end
end
