class ExternalLink < ApplicationRecord
  belongs_to :account, default: -> { linkable.account }
  belongs_to :linkable, polymorphic: true

  class << self
    def record(linkable:, provider:, external_type:, external_id:, external_url: nil, metadata: {})
      find_or_initialize_by(linkable: linkable, provider: provider, external_type: external_type).tap do |link|
        link.update!(external_id: external_id, external_url: external_url, metadata: metadata)
      end
    end
  end
end
