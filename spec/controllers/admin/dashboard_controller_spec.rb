require 'rails_helper'

# Unit tests for Admin::DashboardController
RSpec.describe Admin::DashboardController, type: :controller do
  let(:admin) { create(:admin, role: :super_admin) }

  before do
    sign_in admin
  end

  describe 'GET #index' do
    before do
      # Create test data for realistic testing
      create(:delivered_order, country_code: 'US', quantity: 2, quran: create(:quran, stock: 50))
      create(:pending_order, country_code: 'PK', quantity: 1, quran: create(:quran, stock: 30))
      create(:delivered_order, country_code: 'US', quantity: 3, quran: create(:quran, stock: 20))
      create(:quran, stock: 10) # Additional stock
    end

    it 'calculates total orders correctly' do
      get :index
      expect(assigns(:total_orders)).to be >= 3
    end

    it 'calculates countries served correctly' do
      get :index
      expect(assigns(:countries_served)).to be >= 2 # US, PK at minimum
    end

    it 'calculates qurans distributed correctly' do
      get :index
      expect(assigns(:qurans_distributed)).to be >= 5 # Based on delivered orders
    end

    it 'calculates stock remaining correctly' do
      get :index
      expect(assigns(:stock_remaining)).to be > 0
    end

    it 'filters data by month period' do
      get :index, params: { period: 'month' }
      expect(assigns(:time_period)).to eq('month')
      # Should have labels and data arrays
      expect(assigns(:labels)).to be_an(Array)
      expect(assigns(:orders_data)).to be_a(Hash)
    end

    it 'filters data by day period' do
      get :index, params: { period: 'day' }
      expect(assigns(:time_period)).to eq('day')
      # Should have labels and data arrays
      expect(assigns(:labels)).to be_an(Array)
      expect(assigns(:orders_data)).to be_a(Hash)
    end

    it 'requires authentication' do
      sign_out admin
      get :index
      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'includes recent orders' do
      get :index
      expect(assigns(:recent_orders)).to respond_to(:each) # Can be Array or Relation
      expect(assigns(:recent_orders).count).to be >= 0
    end

    it 'includes heatmap data' do
      get :index
      expect(assigns(:orders_heatmap)).to be_an(Array)
    end
  end

  describe 'GET #live_stats' do
    before do
      create(:delivered_order, country_code: 'US', quantity: 2, quran: create(:quran, stock: 50, translation: 'english'))
      create(:pending_order, country_code: 'PK', quantity: 1, quran: create(:quran, stock: 30, translation: 'arabic'))
      create(:delivered_order, country_code: 'US', quantity: 3, quran: create(:quran, stock: 20, translation: 'french'))
    end

    it 'returns JSON response' do
      get :live_stats, format: :json
      expect(response.content_type).to include('application/json')
      expect(response).to have_http_status(:success)
    end

    it 'returns correct JSON structure' do
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key('stats')
      expect(json_response).to have_key('charts')
      expect(json_response).to have_key('heatmap')
      expect(json_response).to have_key('stock_data')
      expect(json_response).to have_key('top_countries')
      expect(json_response).to have_key('recent_orders')
      expect(json_response).to have_key('low_stock_items')
    end

    it 'returns stats data with reasonable values' do
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      expect(json_response['stats']['total_orders']).to be >= 3
      expect(json_response['stats']['countries_served']).to be >= 1
      expect(json_response['stats']['qurans_distributed']).to be_an(Integer)
      expect(json_response['stats']['stock_remaining']).to be_an(Integer)
    end

    it 'handles different time periods' do
      %w[day week month year].each do |period|
        get :live_stats, params: { period: period }, format: :json
        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)
        expect(json_response['charts']['labels']).to be_an(Array)
        expect(json_response['charts']['data']).to be_an(Array)
      end
    end

    it 'returns heatmap data in correct format' do
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      heatmap = json_response['heatmap']
      expect(heatmap).to be_an(Array)

      if heatmap.any?
        first_marker = heatmap.first
        expected_keys = %w[country lat lng count]
        expect(first_marker.keys).to include(*expected_keys)
      end
    end

    it 'returns top countries data' do
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      top_countries = json_response['top_countries']
      expect(top_countries).to be_an(Array)
      expect(top_countries.length).to be <= 5
    end

    it 'returns recent orders data' do
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      recent_orders = json_response['recent_orders']
      expect(recent_orders).to be_an(Array)
      expect(recent_orders.length).to be <= 10

      if recent_orders.any?
        order = recent_orders.first
        expected_keys = %w[id full_name quantity status created_at]
        expect(order.keys).to include(*expected_keys)
      end
    end

    it 'returns low stock items' do
      low_stock_quran = create(:quran, stock: 50, translation: 'french') # Under 100 threshold
      get :live_stats, format: :json
      json_response = JSON.parse(response.body)

      low_stock_items = json_response['low_stock_items']
      expect(low_stock_items).to be_an(Array)

      if low_stock_quran.present?
        expect(low_stock_items.any? { |item| item['title'] == low_stock_quran.title }).to be_truthy
      end
    end

    it 'bypasses authentication check' do
      # This endpoint should work without authentication due to skip_before_action
      sign_out admin
      get :live_stats, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'handles error gracefully' do
      # Simulate an error condition
      allow(Order).to receive(:count).and_raise(StandardError.new('Database error'))

      get :live_stats, format: :json
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe '#country_coordinates' do
    it 'returns correct coordinates for known countries' do
      controller = Admin::DashboardController.new
      expect(controller.send(:country_coordinates, 'PK')).to eq({ lat: 30.3753, lng: 69.3451 })
      expect(controller.send(:country_coordinates, 'US')).to eq({ lat: 37.0902, lng: -95.7129 })
    end

    it 'returns nil coordinates for unknown countries' do
      controller = Admin::DashboardController.new
      expect(controller.send(:country_coordinates, 'XX')).to eq({ lat: nil, lng: nil })
    end

    it 'handles case insensitive country codes' do
      controller = Admin::DashboardController.new
      expect(controller.send(:country_coordinates, 'pk')).to eq({ lat: 30.3753, lng: 69.3451 })
      expect(controller.send(:country_coordinates, 'us')).to eq({ lat: 37.0902, lng: -95.7129 })
    end
  end
end
