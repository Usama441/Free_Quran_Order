# app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!

  def index
    @total_orders       = Order.count
    @qurans_distributed = Order.sum(:quantity)
    @stock_remaining    = Quran.sum(:stock)

    # Heatmap: group by country_code
    @orders_heatmap = Order.group(:country_code).count

    # Monthly Orders (last 12 months)
    @monthly_orders = Order.group_by_month(:created_at, last: 12, format: "%b").count

    # Stock by translation
    @stock_by_translation = Quran.group(:translation).sum(:stock)
  end
end
