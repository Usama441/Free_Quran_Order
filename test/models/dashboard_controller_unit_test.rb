require 'test_helper'

class DashboardControllerUnitTest < ActiveSupport::TestCase
  def setup
    @controller = Admin::DashboardController.new
  end

  test '#country_coordinates returns correct coordinates for known countries' do
    assert_equal({ lat: 30.3753, lng: 69.3451 }, @controller.send(:country_coordinates, 'PK'))
    assert_equal({ lat: 37.0902, lng: -95.7129 }, @controller.send(:country_coordinates, 'US'))
    assert_equal({ lat: 55.3781, lng: -3.4360 }, @controller.send(:country_coordinates, 'GB'))
    assert_equal({ lat: 23.4241, lng: 53.8478 }, @controller.send(:country_coordinates, 'AE'))
  end

  test '#country_coordinates handles case insensitive input' do
    assert_equal({ lat: 30.3753, lng: 69.3451 }, @controller.send(:country_coordinates, 'pk'))
    assert_equal({ lat: 30.3753, lng: 69.3451 }, @controller.send(:country_coordinates, 'Pk'))
    assert_equal({ lat: 30.3753, lng: 69.3451 }, @controller.send(:country_coordinates, 'PK'))
  end

  test '#country_coordinates returns nil for unknown countries' do
    assert_equal({ lat: nil, lng: nil }, @controller.send(:country_coordinates, 'XX'))
    assert_equal({ lat: nil, lng: nil }, @controller.send(:country_coordinates, 'UNKNOWN'))
    assert_equal({ lat: nil, lng: nil }, @controller.send(:country_coordinates, ''))
  end

  test 'country coordinates data structure is complete' do
    coordinates = @controller.send(:country_coordinates, 'PK')
    assert_includes coordinates.keys, :lat
    assert_includes coordinates.keys, :lng
    assert coordinates[:lat].is_a?(Numeric)
    assert coordinates[:lng].is_a?(Numeric)
  end

  test 'country coordinates handles major Islamic countries' do
    # Test for countries that should definitely have coordinates
    major_countries = ['SA', 'AE', 'KW', 'QA', 'OM', 'BH', 'EG', 'JO', 'IR', 'AF', 'PK', 'BD', 'MY', 'ID', 'TR']

    major_countries.each do |country|
      coordinates = @controller.send(:country_coordinates, country)
      assert_not_nil coordinates[:lat] && coordinates[:lng],
                     "Country #{country} should have coordinates defined"
    end

    # Test that unknown countries return nil coordinates
    unknown_country = @controller.send(:country_coordinates, 'ZZ')
    assert_nil unknown_country[:lat]
    assert_nil unknown_country[:lng]
  end
end
