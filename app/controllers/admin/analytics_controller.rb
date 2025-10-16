class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_admin!

  def orders
    # Order analytics data
    @total_orders = Order.count
    @orders_today = Order.where('created_at >= ?', Date.today).count
    @orders_this_week = Order.where('created_at >= ?', 1.week.ago).count
    @orders_this_month = Order.where('created_at >= ?', 1.month.ago).count

    # Order trends by time period
    @daily_orders = Order.where('created_at >= ?', 30.days.ago)
                          .group_by_day(:created_at, format: "%m/%d").count
    @weekly_orders = Order.where('created_at >= ?', 12.weeks.ago)
                          .group_by_week(:created_at).count
    @monthly_orders = Order.where('created_at >= ?', 12.months.ago)
                           .group_by_month(:created_at, format: "%b %Y").count

    # Order distribution by quantity
    @quantity_distribution = Order.group(:quantity).count.sort_by { |k, v| k }

    # Average order value (in this case, quantity since all free)
    @avg_quantity_per_order = Order.average(:quantity).round(2)
  end

  def customers
    # Customer insights data
    @unique_customers = Order.distinct.pluck(:email).count
    @repeat_customers = Order.group(:email).having('COUNT(*) > 1').count.keys.count
    @first_time_customers = @unique_customers - @repeat_customers

    # Customer demographics
    @top_countries = Order.group(:country_code).count.sort_by { |k, v| -v }.first(10)
    @customer_emails = Order.pluck(:email).uniq

    # Order patterns
    @orders_per_customer = Order.group(:email).count.values.sort.reverse
    @avg_orders_per_customer = (@total_orders.to_f / @unique_customers).round(2)
  end

  def geography
    # Geographic analytics data
    @countries_data = Order.group(:country_code).count.map do |country_code, count|
      lat_lng = country_coordinates(country_code)
      {
        country: country_code,
        orders: count,
        lat: lat_lng[:lat],
        lng: lat_lng[:lng]
      }
    end.reject { |c| c[:lat].nil? }.sort_by { |c| -c[:orders] }

    # Regional statistics
    @asian_countries = Order.where(country_code: ['PK', 'IN', 'BD', 'LK', 'NP', 'BT', 'MY', 'ID']).count
    @middle_east_countries = Order.where(country_code: ['AE', 'SA', 'BH', 'QA', 'OM', 'KW', 'IR', 'EG']).count
    @european_countries = Order.where(country_code: ['GB', 'DE', 'FR', 'IT', 'ES', 'TR']).count
    @american_countries = Order.where(country_code: ['US', 'CA']).count
  end

  def reports
    # Report generation data
    @reports_data = {
      daily: generate_report_data('day', 30),
      weekly: generate_report_data('week', 12),
      monthly: generate_report_data('month', 12),
      total: Order.count
    }

    # Performance metrics
    @total_qurans_distributed = Order.sum(:quantity)
    @current_stock = Quran.sum(:stock)
    @countries_reached = Order.distinct.pluck(:country_code).count

    # Calculate data for display
    @reports = {
      daily: @reports_data[:daily],
      weekly: @reports_data[:weekly],
      monthly: @reports_data[:monthly]
    }
  end

  def download_csv
    # Generate CSV dynamically from database
    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Order ID', 'Customer Name', 'Email', 'Country', 'City', 'Quantity', 'Order Date', 'Phone']
      Order.order(created_at: :desc).includes(:quran).find_each do |order|
        csv << [
          order.id,
          order.full_name,
          order.email,
          order.country_code,
          order.city,
          order.quantity,
          order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          order.phone
        ]
      end
    end
    send_data csv_data, filename: "quran_orders_report_#{Date.today.strftime('%Y-%m-%d')}.csv", type: 'text/csv'
  end

  private

  def generate_report_data(period, count)
    case period
    when 'day'
      Order.where('created_at >= ?', count.days.ago)
           .group_by_day(:created_at, last: count).count
    when 'week'
      Order.where('created_at >= ?', count.weeks.ago)
           .group_by_week(:created_at, last: count).count
    when 'month'
      Order.where('created_at >= ?', count.months.ago)
           .group_by_month(:created_at, last: count).count
    end
  end

  def generate_csv_report
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Order ID', 'Customer Name', 'Email', 'Country', 'City', 'Quantity', 'Order Date']

      Order.includes(:quran).find_each do |order|
        csv << [
          order.id,
          order.full_name,
          order.email,
          order.country_code,
          order.city,
          order.quantity,
          order.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end

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
