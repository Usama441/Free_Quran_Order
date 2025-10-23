class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!
  skip_before_action :authenticate_admin!, only: [:live_stats]
  skip_before_action :verify_authenticity_token, only: [:live_stats]

  def index
    @total_orders       = Order.count
    @countries_served   = Order.distinct.pluck(:country_code).count
    @qurans_distributed = Order.where(status: 'delivered').sum(:quantity)
    @stock_remaining    = Quran.sum(:stock)

    # Period filtering
    @time_period = params[:period] || 'month' # day, week, month, year

    case @time_period
    when 'day'
      @orders_data = Order.where('created_at >= ?', 30.days.ago).group_by_day(:created_at, format: "%m/%d").count
      @labels = @orders_data.keys
    when 'week'
      @orders_data = Order.where('created_at >= ?', 6.months.ago).group_by_week(:created_at, format: "Week %W").count
      @labels = @orders_data.keys
    when 'month'
      @orders_data = Order.where('created_at >= ?', 12.months.ago).group_by_month(:created_at, format: "%b %Y").count
      @labels = @orders_data.keys
    when 'year'
      @orders_data = Order.where('created_at >= ?', 10.years.ago).group_by_year(:created_at, format: "%Y").count
      @labels = @orders_data.keys
    end

    # Heatmap: group by country_code with transformed coordinates
    @orders_heatmap = Order.group(:country_code).count.map do |country_code, count|
      lat_lng = country_coordinates(country_code)
      {
        country: country_code,
        lat: lat_lng[:lat],
        lng: lat_lng[:lng],
        count: count
      }
    end.select { |h| h[:lat] && h[:lng] }

    # Stock by translation
    @stock_by_translation = Quran.group(:translation).sum(:stock)

    # Additional analytics data
    @top_countries = Order.group(:country_code).count.sort_by { |k, v| -v }.first(5)
    @quran_translations = Quran.group(:translation).sum(:stock).sort_by { |k, v| -v }
    @recent_orders = Order.order(created_at: :desc).limit(10)
    @low_stock_items = Quran.where('stock < ?', 100)
    @page_views = 1250 # Mock data - would come from analytics service
    @form_views = @total_orders * 3 # Mock data - would come from analytics
  end

  # API endpoint for live dashboard updates
  def live_stats
    respond_to do |format|
      format.json do
        begin
          # Get current period from params or session
          time_period = params[:period] || session[:dashboard_period] || 'month'

          case time_period
          when 'day'
            orders_data = Order.where('created_at >= ?', 30.days.ago).group_by_day(:created_at, format: "%m/%d").count
            labels = orders_data.keys
          when 'week'
            orders_data = Order.where('created_at >= ?', 6.months.ago).group_by_week(:created_at, format: "Week %W").count
            labels = orders_data.keys
          when 'month'
            orders_data = Order.where('created_at >= ?', 12.months.ago).group_by_month(:created_at, format: "%b %Y").count
            labels = orders_data.keys
          when 'year'
            orders_data = Order.where('created_at >= ?', 10.years.ago).group_by_year(:created_at, format: "%Y").count
            labels = orders_data.keys
          end

          # Heatmap data
          orders_heatmap = Order.group(:country_code).count.map do |country_code, count|
            lat_lng = country_coordinates(country_code)
            {
              country: country_code,
              lat: lat_lng[:lat],
              lng: lat_lng[:lng],
              count: count
            }
          end.select { |h| h[:lat] && h[:lng] }

          # Top countries
          top_countries = Order.group(:country_code).count.sort_by { |k, v| -v }.first(5)

          # Stock data
          stock_by_translation = Quran.group(:translation).sum(:stock)

          # Recent orders
          recent_orders = Order.order(created_at: :desc).limit(10)

          # Low stock items
          low_stock_items = Quran.where('stock < ?', 100)

          render json: {
            stats: {
              total_orders: Order.count,
              countries_served: Order.distinct.pluck(:country_code).count,
              qurans_distributed: Order.where(status: 'delivered').sum(:quantity),
              stock_remaining: Quran.sum(:stock)
            },
            charts: {
              labels: labels || [],
              data: orders_data ? orders_data.values : []
            },
            heatmap: orders_heatmap,
            stock_data: stock_by_translation,
            top_countries: top_countries,
            recent_orders: recent_orders.map do |order|
              {
                id: order.id,
                full_name: order.full_name,
                quantity: order.quantity,
                status: order.status,
                created_at: order.created_at
              }
            end,
            low_stock_items: low_stock_items.map do |item|
              {
                title: item.title,
                stock: item.stock
              }
            end
          }
        rescue StandardError => e
          # Handle any database or other errors gracefully
          Rails.logger.error("Dashboard live_stats error: #{e.message}")
          render json: { error: 'Internal server error', message: 'Failed to load dashboard data' },
                 status: :internal_server_error
        end
      end
    end
  end

  private

  def country_coordinates(country_code)
    coordinates = {
      'PK' => { lat: 30.3753, lng: 69.3451 },  # Pakistan
      'US' => { lat: 37.0902, lng: -95.7129 },  # USA
      'GB' => { lat: 55.3781, lng: -3.4360 },  # UK
      'AE' => { lat: 23.4241, lng: 53.8478 },  # UAE
      'SA' => { lat: 23.8859, lng: 45.0792 },  # Saudi Arabia
      'BH' => { lat: 25.9304, lng: 50.6378 },  # Bahrain
      'QA' => { lat: 25.3548, lng: 51.1839 },  # Qatar
      'OM' => { lat: 21.4735, lng: 55.9754 },  # Oman
      'KW' => { lat: 29.3117, lng: 47.4818 },  # Kuwait
      'EG' => { lat: 26.0963, lng: 29.9788 },  # Egypt
      'IN' => { lat: 20.5937, lng: 78.9629 },  # India
      'AF' => { lat: 33.9391, lng: 67.7100 },  # Afghanistan
      'IR' => { lat: 32.4279, lng: 53.6880 },  # Iran
      'JO' => { lat: 31.9631, lng: 35.9304 },  # Jordan
      'CA' => { lat: 56.1304, lng: -106.3468 }, # Canada
      'AU' => { lat: -25.2744, lng: 133.7751 }, # Australia
      'DE' => { lat: 51.1657, lng: 10.4515 },  # Germany
      'FR' => { lat: 46.2276, lng: 2.2137 },   # France
      'IT' => { lat: 41.8719, lng: 12.5674 },  # Italy
      'ES' => { lat: 40.4637, lng: -3.7492 },  # Spain
      'TR' => { lat: 38.9637, lng: 35.2433 },  # Turkey
      'MY' => { lat: 4.2105, lng: 101.9758 },  # Malaysia
      'ID' => { lat: -0.7893, lng: 113.9213 }, # Indonesia
      'BD' => { lat: 23.6850, lng: 90.3563 },  # Bangladesh
      'LK' => { lat: 7.8731, lng: 80.7718 },   # Sri Lanka
      'NP' => { lat: 28.3949, lng: 84.1240 },  # Nepal
      'BT' => { lat: 27.5142, lng: 90.4336 },  # Bhutan
      'MV' => { lat: 3.2028, lng: 73.2207 }    # Maldives
    }
    coordinates[country_code.upcase] || { lat: nil, lng: nil }
  end
end
