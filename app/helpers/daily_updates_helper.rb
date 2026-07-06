module DailyUpdatesHelper
  def pending_daily_update
    return unless Current.user&.active? && !Current.user.system?
    return unless Current.account&.daily_update_workday?(Date.current)

    update = DailyUpdate.for_user(Current.user)
    update unless update.submitted? || update.late?
  end

  def daily_update_status_badge(daily_update)
    tag.span daily_update.status.titleize, class: daily_update_status_classes(daily_update)
  end

  def daily_update_status_classes(daily_update)
    class_names "daily-update__status", "daily-update__status--#{daily_update.status}"
  end
end
