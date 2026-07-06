class DailyUpdateMailer < ApplicationMailer
  def reminder(user, date)
    @user = user
    @date = date
    mail to: user.identity.email_address, subject: "Your daily update is due today"
  end

  def missing_warning(user, date)
    @user = user
    @date = date
    mail to: user.identity.email_address, subject: "Your daily update is still missing"
  end

  def manager_summary(manager, users, date)
    @manager = manager
    @users = users
    @date = date
    mail to: manager.identity.email_address,
      subject: "#{users.size} missing daily #{"update".pluralize(users.size)}"
  end
end
