class Github::Configuration < ApplicationRecord
  belongs_to :account

  def in_review_column_name
    super.presence || "In Review"
  end
end
