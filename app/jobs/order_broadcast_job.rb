class OrderBroadcastJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order

    # Calculate current stats for dashboard
    stats = {
      total_orders: Order.count,
      countries_served: Order.distinct.pluck(:country_code).count,
      qurans_distributed: Order.sum(:quantity),
      stock_remaining: Quran.sum(:stock)
    }

    # 1. BROADCAST TO DASHBOARD SUBSCRIBERS
    Turbo::StreamsChannel.broadcast_replace_to(
      "dashboard_stats",
      target: "stats_cards",
      partial: "admin/dashboard/stats_cards",
      locals: { stats: stats }
    )

    # 2. BROADCAST TO ORDER MANAGEMENT PAGE
    # Calculate current counts for admin orders page
    counts_data = {
      pending_count: Order.where(status: Order.statuses['pending']).count,
      processing_count: Order.where(status: Order.statuses['processing']).count,
      shipped_count: Order.where(status: Order.statuses['shipped']).count,
      delivered_count: Order.where(status: Order.statuses['delivered']).count
    }

    # Broadcast updated counts to orders page
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "pending-count",
      html: "<h3 class=\"text-2xl font-bold text-red-600\" id=\"pending-count\">#{counts_data[:pending_count]}</h3>"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "processing-count",
      html: "<h3 class=\"text-2xl font-bold text-yellow-600\" id=\"processing-count\">#{counts_data[:processing_count]}</h3>"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "shipped-count",
      html: "<h3 class=\"text-2xl font-bold text-blue-600\" id=\"shipped-count\">#{counts_data[:shipped_count]}</h3>"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "delivered-count",
      html: "<h3 class=\"text-2xl font-bold text-green-600\" id=\"delivered-count\">#{counts_data[:delivered_count]}</h3>"
    )

    # Broadcast order show page status update
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "order-#{order.id}-status-badge",
      html: "<span class=\"px-3 py-1 text-sm font-semibold rounded-full #{
        case order.status
        when 'pending' then 'bg-red-100 text-red-800'
        when 'processing' then 'bg-yellow-100 text-yellow-800'
        when 'shipped' then 'bg-blue-100 text-blue-800'
        when 'delivered' then 'bg-green-100 text-green-800'
        when 'cancelled' then 'bg-red-100 text-red-800'
        else 'bg-gray-100 text-gray-800'
        end
      }\" id=\"order-#{order.id}-status-badge\">#{order.status&.titleize || 'Unknown'}</span>"
    )

    # Highlight the updated order row briefly to show it was changed
    Turbo::StreamsChannel.broadcast_replace_to(
      "admin_orders_live",
      target: "order-row-#{order.id}",
      partial: "admin/orders/order_row_highlight",
      locals: { order: order }
    )
  end
end
