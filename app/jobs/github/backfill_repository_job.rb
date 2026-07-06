class Github::BackfillRepositoryJob < ApplicationJob
  discard_on ActiveJob::DeserializationError

  def perform(repository)
    Current.user = Current.account.system_user
    Github::Backfill.new(repository).run
  end
end
