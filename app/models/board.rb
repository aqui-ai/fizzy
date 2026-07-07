class Board < ApplicationRecord
  include Accessible, AutoPostponing, Board::Storage, Broadcastable, Cards, Entropic, Filterable, Publishable, ::Storage::Tracked, Triageable

  DEFAULT_TAGS = %w[ blocked decision-required quotation payment evidence-attached evidence-missing deadline-risk waiting-external-party management-review ].freeze

  KEY_FORMAT = /\A[A-Z][A-Z0-9]{1,9}\z/
  KEY_MAX_LENGTH = 6

  belongs_to :creator, class_name: "User", default: -> { Current.user }
  belongs_to :account, default: -> { creator.account }

  has_rich_text :public_description

  has_many :tags, dependent: :destroy
  has_many :events
  has_many :webhooks, dependent: :destroy

  normalizes :key, with: -> { it.to_s.upcase.strip }

  validates :key, presence: true, format: { with: KEY_FORMAT }, uniqueness: { scope: :account_id }

  before_validation :assign_key, on: :create
  after_create :seed_default_tags

  scope :alphabetically, -> { order("lower(name)") }
  scope :ordered_by_recently_accessed, -> { merge(Access.ordered_by_recently_accessed) }

  def self.generate_key(name, account)
    base = key_base_from(name)
    candidate, suffix = base, 1

    while account&.boards&.exists?(key: candidate)
      suffix += 1
      candidate = "#{base.first(KEY_MAX_LENGTH - suffix.to_s.length)}#{suffix}"
    end

    candidate
  end

  def self.key_base_from(name)
    words = name.to_s.scan(/[A-Za-z0-9]+/)
    base = (words.many? ? words.last : words.first).to_s.upcase
    base = "BOARD#{base}" unless base.match?(/\A[A-Z]/)
    base.first(KEY_MAX_LENGTH)
  end

  def seed_default_tags
    DEFAULT_TAGS.each { |title| tags.find_or_create_by!(title: title) }
  end

  private
    def assign_key
      self.key = self.class.generate_key(name, account || creator&.account) if key.blank?
    end
end
