class ReportsController < ApplicationController
  WINDOW_OPTIONS = [ 7, 30, 90 ].freeze
  DEFAULT_WINDOW = 30

  before_action :ensure_admin

  def show
    @window_days = window_days
    @window = @window_days.days.ago.beginning_of_day..Time.current
    @dashboard = Report::Dashboard.new(cards: Current.user.accessible_cards.published, window: @window)
  end

  private
    def window_days
      days = params[:days].to_i
      WINDOW_OPTIONS.include?(days) ? days : DEFAULT_WINDOW
    end
end
