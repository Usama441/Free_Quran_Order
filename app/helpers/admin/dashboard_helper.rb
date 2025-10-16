module Admin::DashboardHelper
  COUNTRY_DATA = {
    "PK" => { name: "Pakistan",   lat: 30.3753, lng: 69.3451 },
    "UK" => { name: "UK",         lat: 55.3781, lng: -3.4360 },
    "US" => { name: "USA",        lat: 37.0902, lng: -95.7129 },
    "TR" => { name: "Turkey",     lat: 38.9637, lng: 35.2433 },
    "ID" => { name: "Indonesia",  lat: -0.7893, lng: 113.9213 },
    "CA" => { name: "Canada",     lat: 56.1304, lng: -106.3468 }
    # Add more country codes as needed
  }

  def country_name(code)
    COUNTRY_DATA[code]&.dig(:name) || "Unknown"
  end

  def country_lat(code)
    COUNTRY_DATA[code]&.dig(:lat) || 0
  end

  def country_lng(code)
    COUNTRY_DATA[code]&.dig(:lng) || 0
  end
end