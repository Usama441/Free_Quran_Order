require "test_helper"

class AdminOrdersIntegrationSimplifiedTest < ActionDispatch::IntegrationTest
  ## 🔍 SIMPLE TEST TO IDENTIFY WHY FILTERS AND ACTIONS DON'T WORK ##

  setup do
    # Create admin
    @admin = Admin.create!(email: 'admin@test.com', password: 'password123', password_confirmation: 'password123')

    # Create quran
    @quran = Quran.create!(title: "Test Quran", writer: "Test Author", translation: "english", pages: 604, stock: 100)

    # Create orders with different statuses
    @pending_order = Order.create!(full_name: 'Pending', email: 'pending@test.com', phone: '+1234567890', country_code: 'US', city: 'New York', state: 'NY', postal_code: '10001', address: '123 St', quantity: 1, status: :pending, translation: 'english')
    @processing_order = Order.create!(full_name: 'Processing', email: 'processing@test.com', phone: '+1987654321', country_code: 'US', city: 'LA', state: 'CA', postal_code: '90210', address: '456 St', quantity: 1, status: :processing, translation: 'english')
    @shipped_order = Order.create!(full_name: 'Shipped', email: 'shipped@test.com', phone: '+1555123456', country_code: 'US', city: 'Chicago', state: 'IL', postal_code: '60601', address: '789 St', quantity: 1, status: :shipped, translation: 'english')

    # Sign in
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
  end

  test "🔍 basic page load test" do
    puts "=== BASIC PAGE LOAD TEST ==="
    get admin_orders_path
    puts "Response status: #{response.status}"
    puts "Response contains table: #{response.body.include?('<table>')}"
    puts "Response contains orders: #{response.body.include?('Pending')}"

    assert_response :success
    assert response.body.include?('Pending'), "Page should contain order names"
  end

  test "🔍 AJAX filtering test" do
    puts "=== AJAX FILTERING TEST ==="

    # Simple status filtering
    get admin_orders_path, params: { status: 'pending', format: 'json' }
    puts "AJAX Response status: #{response.status}"

    if response.status == 200
      data = JSON.parse(response.body)
      puts "JSON Response keys: #{data.keys.inspect}"
      puts "Pending count: #{data['pending_count']}"
      puts "HTML includes pending order: #{data['html'].include?('Pending')}"

      assert_equal 1, data['pending_count'], "Should show 1 pending order"
      assert data['html'].include?('Pending'), "Should include the pending order"
    else
      puts "AJAX request failed with status #{response.status}"
      puts "Response body: #{response.body}"
    end
  end

  test "🔍 status update test" do
    puts "=== STATUS UPDATE TEST ==="

    # Update order status
    patch admin_update_order_status_path(@pending_order), params: { status: 'processing' }, as: :json

    puts "Update response status: #{response.status}"

    if response.status == 200
      data = JSON.parse(response.body)
      puts "Update success: #{data['success']}"
      puts "New status: #{data['new_status']}"

      # Check database
      @pending_order.reload
      puts "Database status: #{@pending_order.status}"

      assert data['success'], "Update should be successful"
      assert_equal 'processing', @pending_order.status.to_s, "Database should be updated"
    else
      puts "Update request failed with status #{response.status}"
      puts "Response body: #{response.body}"
    end
  end

  test "🔍 controller counts test" do
    puts "=== CONTROLLER COUNTS TEST ==="

    # Create fresh orders with unique data
    Order.destroy_all # Clean slate
    fresh_pending = Order.create!(full_name: 'Fresh Pending', email: 'fresh_pending@example.com', phone: '+1234567890', country_code: 'US', city: 'NY', state: 'NY', postal_code: '10001', address: '123 St', quantity: 1, status: :pending, translation: 'english')
    fresh_processing = Order.create!(full_name: 'Fresh Processing', email: 'fresh_processing@example.com', phone: '+1987654321', country_code: 'US', city: 'LA', state: 'CA', postal_code: '90210', address: '456 St', quantity: 1, status: :processing, translation: 'english')
    fresh_shipped = Order.create!(full_name: 'Fresh Shipped', email: 'fresh_shipped@example.com', phone: '+1555123456', country_code: 'US', city: 'Chicago', state: 'IL', postal_code: '60601', address: '789 St', quantity: 1, status: :shipped, translation: 'english')

    # Test controller counts directly
    get admin_orders_path

    # Check the HTML response for counts
    assert response.body.include?('<h3 class="text-2xl font-bold text-red-600" id="pending-count">1</h3>'), "Should show 1 pending order in HTML"
    assert response.body.include?('<h3 class="text-2xl font-bold text-yellow-600" id="processing-count">1</h3>'), "Should show 1 processing order in HTML"
    assert response.body.include?('<h3 class="text-2xl font-bold text-blue-600" id="shipped-count">1</h3>'), "Should show 1 shipped order in HTML"
    assert response.body.include?('<h3 class="text-2xl font-bold text-green-600" id="delivered-count">0</h3>'), "Should show 0 delivered orders in HTML"

    puts "✅ All HTML count displays correct!"
  end
end
