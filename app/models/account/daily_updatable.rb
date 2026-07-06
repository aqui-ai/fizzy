module Account::DailyUpdatable
  extend ActiveSupport::Concern

  CUTOFF_HOURS = (6..22).to_a.freeze

  included do
    has_many :daily_updates, dependent: :destroy

    validates :daily_update_cutoff_hour, inclusion: { in: CUTOFF_HOURS }
  end

  def daily_update_cutoff_for(date)
    date.in_time_zone.change(hour: daily_update_cutoff_hour)
  end

  def daily_update_workday?(date)
    !daily_update_exclude_weekends? || date.on_weekday?
  end
end
