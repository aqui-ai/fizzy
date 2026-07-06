class Board < ApplicationRecord
  include Accessible, AutoPostponing, Board::Storage, Broadcastable, Cards, Entropic, Filterable, Publishable, ::Storage::Tracked, Triageable

  DEFAULT_TAGS = %w[ blocked decision-required quotation payment evidence-attached evidence-missing deadline-risk waiting-external-party management-review ].freeze

  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { creator.account }

  has_rich_text :public_description

  has_many :tags, dependent: :destroy
  has_many :events
  has_many :webhooks, dependent: :destroy

  after_create :seed_default_tags

  scope :alphabetically, -> { order("lower(name)") }
  scope :ordered_by_recently_accessed, -> { merge(Access.ordered_by_recently_accessed) }

  def seed_default_tags
    DEFAULT_TAGS.each { |title| tags.find_or_create_by!(title: title) }
  end
end
