# Active Record encryption keys.
#
# Production reads keys from encrypted credentials automatically when
# `active_record_encryption` is present there — add them with 1Password/kamal:
#
#   bin/rails db:encryption:init   # prints the three keys
#   bin/rails credentials:edit     # paste them under active_record_encryption:
#
# Development and test fall back to fixed, non-secret keys so the app runs
# locally without provisioning real keys. Production intentionally has no
# fallback: if credentials lack the keys, encrypted attributes raise loudly.
Rails.application.configure do
  config.active_record.encryption.support_unencrypted_data = true

  if Rails.application.credentials.active_record_encryption.blank? && !Rails.env.production?
    config.active_record.encryption.primary_key = "insecure-development-primary-key-000000000"
    config.active_record.encryption.deterministic_key = "insecure-development-deterministic-key-0000"
    config.active_record.encryption.key_derivation_salt = "insecure-development-key-derivation-salt-00"
  end
end
