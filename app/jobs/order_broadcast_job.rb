class OrderBroadcastJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    # Broadcast real-time updates to dashboard
    order = Order.find_by(id: order_id)
    return unless order

    # Calculate stats
    stats = {
      total_orders: Order.count,
      countries_served: Order.distinct.pluck(:country_code).count,
      qurans_distributed: Order.sum(:quantity),
      stock_remaining: Quran.sum(:stock)
    }

    # Broadcast to dashboard subscribers
    Turbo::StreamsChannel.broadcast_replace_to(
      "dashboard_stats",
      target: "stats_cards",
      partial: "admin/dashboard/stats_cards",
      locals: { stats: stats }
    )
  end
end
