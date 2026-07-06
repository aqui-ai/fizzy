class Reports::GithubReportsController < ApplicationController
  before_action :ensure_admin

  def show
    @report = Report::Github.new(Current.account)
  end
end
