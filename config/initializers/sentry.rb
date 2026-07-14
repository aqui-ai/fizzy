if !Fizzy.saas? && ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV.fetch("SENTRY_DSN")
    config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
    config.release = ENV["SENTRY_RELEASE"].presence
    config.send_default_pii = false
    config.traces_sample_rate = nil
    config.breadcrumbs_logger = []
    config.excluded_exceptions += [ "ActiveRecord::ConcurrentMigrationError" ]

    # Receive explicit Rails.error reports and Active Job retry/discard reports.
    config.rails.register_error_subscriber = true
  end
end
