class Admin::GeographyController < ApplicationController
  before_action :authenticate_admin!

  def show
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

    # Top performing countries
    @top_countries = @countries_data.first(5)

    # Geographic distribution metrics
    @total_countries_reached = @countries_data.count
    @avg_orders_per_country = (@countries_data.sum { |c| c[:orders] }.to_f / @total_countries_reached).round(1)
    @most_active_country = @countries_data.first
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
