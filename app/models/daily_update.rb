class DailyUpdate < ApplicationRecord
  belongs_to :account, default: -> { user.account }
  belongs_to :user

  enum :status, %w[ draft submitted late missing ].index_by(&:itself)

  validates :user_id, uniqueness: { scope: [ :account_id, :work_on ] }

  scope :for_date, ->(date) { where(work_on: date) }

  class << self
    def for_user(user, date: Date.current)
      find_or_initialize_by(user: user, work_on: date)
    end

    def remind_due(as_of: Date.current)
      remind_pending(as_of) { |user| DailyUpdateMailer.reminder(user, as_of) }
    end

    def remind_missing(as_of: Date.current)
      remind_pending(as_of) { |user| DailyUpdateMailer.missing_warning(user, as_of) }
    end

    def mark_missing_due(as_of: Date.current)
      each_active_user(as_of) do |_user, update|
        update.mark_missing! if update.pending?
      end
    end

    def notify_managers_of_missing_updates(as_of: Date.current)
      Account.find_each do |account|
        next unless account.daily_update_workday?(as_of)
        Current.with_account(account) do
          notify_managers_for account, missing_users_for(account, as_of), as_of
        end
      end
    end

    private
      def remind_pending(as_of, &mailer)
        each_active_user(as_of) do |user, update|
          mailer.call(user).deliver_now if update.pending?
        end
      end

      def each_active_user(as_of)
        Account.find_each do |account|
          next unless account.daily_update_workday?(as_of)
          Current.with_account(account) do
            account.users.active.each { |user| yield user, for_user(user, date: as_of) }
          end
        end
      end

      def missing_users_for(account, as_of)
        account.daily_updates.for_date(as_of).missing.includes(:user).map(&:user)
      end

      def notify_managers_for(account, missing_users, as_of)
        return if missing_users.none?
        account.users.admin.each do |manager|
          DailyUpdateMailer.manager_summary(manager, missing_users, as_of).deliver_now
        end
      end
  end

  def submit(now: Time.current)
    self.submitted_at ||= now
    self.status = after_cutoff?(submitted_at) ? :late : :submitted
    save!
  end

  def save_draft
    self.status = :draft if pending?
    save!
  end

  def mark_missing!
    update! status: :missing
  end

  def pending?
    new_record? || draft?
  end

  def cutoff_at
    (account || user.account).daily_update_cutoff_for(work_on)
  end

  def after_cutoff?(time = Time.current)
    time > cutoff_at
  end
end
