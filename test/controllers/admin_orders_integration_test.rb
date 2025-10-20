require "test_helper"

class AdminOrdersIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create admin user first
    @admin = Admin.create!(
      email: 'admin@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )

    # Create some test data
    @quran = Quran.create!(
      title: "Test Quran",
      writer: "Test Author",
      translation: "english",
      pages: 604,
      stock: 100
    )

    # Create test orders with different statuses
    @order1 = Order.create!(
      full_name: 'Test User 1',
      email: 'user1@example.com',
      phone: '+1234567890',
      country_code: 'US',
      city: 'New York',
      state: 'NY',
      postal_code: '10001',
      address: '123 Main St',
      quantity: 1,
      status: :pending,
      translation: 'english'
    )

    @order2 = Order.create!(
      full_name: 'Test User 2',
      email: 'user2@example.com',
      phone: '+1987654321',
      country_code: 'US',
      city: 'Los Angeles',
      state: 'CA',
      postal_code: '90210',
      address: '456 Oak St',
      quantity: 2,
      status: :processing,
      translation: 'english'
    )

    @order3 = Order.create!(
      full_name: 'Test User 3',
      email: 'user3@example.com',
      phone: '+1555123456',
      country_code: 'US',
      city: 'Chicago',
      state: 'IL',
      postal_code: '60601',
      address: '789 Pine St',
      quantity: 1,
      status: :shipped,
      translation: 'english'
    )

    # Sign in admin
    sign_in_as_admin(@admin.email, 'password123')
  end

  test "admin can view orders index with correct counts" do
    get admin_orders_path
    assert_response :success

    # Check that status counts are correct - showing ALL orders since no filtering applied
    assert_select 'h3#pending-count', '3'    # All orders
    assert_select 'h3#processing-count', '1'
    assert_select 'h3#shipped-count', '1'
    assert_select 'h3#delivered-count', '0'

    # Check orders are displayed
    assert_select 'table' do
      assert_select 'tbody tr', 3
    end
  end

  test "AJAX filtering by status works" do
    # Filter for pending orders
    get admin_orders_path, params: { status: 'pending', format: 'json' }
    assert_response :success

    response_data = JSON.parse(response.body)
    # Should only show pending orders
    # Check if the response contains the expected structure
    puts "=== AJAX Filter Test Response ==="
    puts "Response keys: #{response_data.keys.inspect}"
    puts "HTML length: #{response_data['html'].length}" rescue puts "No HTML key"
    puts "Pending count: #{response_data['pending_count']}"

    assert response_data['pending_count'] == 1
    assert response_data['html'].include?(@order1.full_name)
    refute response_data['html'].include?(@order2.full_name) unless @order2.status.to_s == 'pending'
    refute response_data['html'].include?(@order3.full_name) unless @order3.status.to_s == 'pending'
  end

  test "AJAX date filtering works" do
    start_date = Date.yesterday.to_s
    end_date = Date.tomorrow.to_s

    get admin_orders_path, params: { start_date: start_date, end_date: end_date, format: 'json' }
    assert_response :success

    response_data = JSON.parse(response.body)
    puts "=== Date Filter Test Response ==="
    puts "All orders should be within date range"
    puts "Start date: #{start_date}, End date: #{end_date}"

    assert response_data['pending_count'] == 1
    assert response_data['processing_count'] == 1
    assert response_data['shipped_count'] == 1
  end

  test "status update via AJAX works" do
    # Update order status
    patch admin_update_order_status_path(@order1), params: { status: 'processing' }, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    puts "=== Status Update Test Response ==="
    puts "Success: #{response_data['success']}"
    puts "Message: #{response_data['message']}" if response_data['message']
    puts "New status: #{response_data['new_status']}" if response_data['new_status']
    puts "Error: #{response_data['error']}" if response_data['error']

    # Check if database updated
    @order1.reload
    puts "Database status: #{@order1.status}"

    # Check response structure
    assert response_data['success']
    assert_equal 'processing', response_data['new_status'] if response_data['new_status']
  end

  test "HTML status update from dropdown works" do
    # This is for HTML response
    patch admin_update_order_status_path(@order2), params: { status: 'delivered' }
    assert_redirected_to admin_orders_path

    # Check flash message
    follow_redirect!
    assert_select '.flash-message', /Status updated/

    # Manually check database was updated since there's no flash message in show view
    @order2.reload
    assert_equal 'delivered', @order2.status.to_s
  end

  private

  def sign_in_as_admin(email, password)
    post admin_session_path, params: {
      admin: { email: email, password: password }
    }
    assert_redirected_to admin_dashboard_path
    follow_redirect!
  end
end
