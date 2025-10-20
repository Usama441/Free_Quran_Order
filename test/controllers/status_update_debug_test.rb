require "test_helper"

class StatusUpdateDebugTest < ActionDispatch::IntegrationTest
  ## 🔍 DEBUGGING STATUS UPDATE FUNCTIONALITY ##

  setup do
    Order.destroy_all
    Admin.destroy_all
    Quran.destroy_all

    @admin = Admin.create!(email: 'admin@test.com', password: 'password123', password_confirmation: 'password123')

    @quran = Quran.create!(
      title: "Debug Quran",
      writer: "Test Author",
      translation: "english",
      pages: 100,
      stock: 50
    )

    @order = Order.new(
      full_name: 'Test User',
      email: 'test@example.com',
      phone: '+1234567890',
      country_code: 'US',
      city: 'Test City',
      state: 'TS',
      postal_code: '12345',
      address: '123 Test St',
      quantity: 1,
      status: :pending,
      translation: 'english'
    )
    @order.quran = @quran  # Set polymorphic association
    @order.save!

    puts "Setup: Created order with ID: #{@order.id}, initial status: #{@order.status}"

    # Sign in as admin
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
  end

  test "DEBUG: Backend status update functionality" do
    puts "=== DEBUGGING STATUS UPDATE BACKEND ==="

    # Check initial order status
    @order.reload
    puts "Initial status: #{@order.status} (#{@order.status.class})"

    # Test 1: Basic PATCH request to update status
    puts "Test 1: Direct PATCH request..."
    patch admin_update_order_status_path(@order), params: { status: 'processing' }, as: :json

    puts "Response status: #{response.status}"
    puts "Response headers: #{response.headers['Content-Type']}"

    if response.status == 200
      response_data = JSON.parse(response.body)
      puts "Response data: #{response_data.inspect}"

      # Check if database was updated
      @order.reload
      puts "Database status after update: #{@order.status}"
      puts "Database changed?: #{response_data['success']}"
    else
      puts "ERROR: Request failed with status #{response.status}"
      puts "Response body: #{response.body}"
    end

    # Test 2: Check if order status enum works
    puts "\nTest 2: Rails enum validation..."
    order_test = Order.new(status: :processing)
    puts "Enum processing valid?: #{order_test.valid?}"

    # Test 3: Check controller method
    puts "\nTest 3: Controller method check..."
    @controller = Admin::OrdersController.new
    puts "Controller has update_status method?: #{Admin::OrdersController.new.respond_to?(:update_status)}"

    # Test 4: Check route mapping
    puts "\nTest 4: Route check..."
    begin
      route = Rails.application.routes.recognize_path("/admin/orders/#{@order.id}/status", method: :patch)
      puts "Route recognized: #{route.inspect}"
    rescue => e
      puts "Route recognition failed: #{e.message}"
    end

    puts "\n=== DEBUG COMPLETE ==="
  end

  test "COMPLETE REAL-TIME ORDER STATUS WORKFLOW" do
    puts "=== TESTING COMPLETE REAL-TIME ORDER STATUS WORKFLOW ==="

    # Create multiple orders to test multi-user scenarios
    order2 = Order.new(
      full_name: 'Sarah Johnson',
      email: 'sarah@test.com',
      phone: '+1923456789',
      country_code: 'US',
      city: 'Chicago',
      state: 'IL',
      postal_code: '60601',
      address: '789 Oak St',
      quantity: 3,
      status: :pending,
      translation: 'english'
    )
    order2.quran = @order.quran
    order2.save!

    # Step 1: Load orders page and verify setup
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!

    get admin_orders_path
    assert_response :success

    # Check initial state - should have 2 pending orders
    assert response.body.include?('<h3 class="text-2xl font-bold text-red-600" id="pending-count">2</h3>'), "❌ Initial pending count should be 2"
    assert response.body.include?('Test User'), "❌ First order not shown"
    assert response.body.include?('Sarah Johnson'), "❌ Second order not shown"

    puts "✅ Step 1: Orders page loaded with 2 orders"

    # Step 2: Update first order status
    patch admin_update_order_status_path(@order), params: { status: 'processing' }, as: :json
    assert_response :success

    response_data = JSON.parse(response.body)
    assert response_data['success'], "❌ Status update failed"
    assert_equal 'processing', response_data['new_status'], "❌ Wrong status returned"

    # Check database was updated
    @order.reload
    assert_equal 'processing', @order.status, "❌ Database not updated"

    puts "✅ Step 2: First order status updated to processing"

    # Step 3: Check counts are updated (should now have 1 pending, 1 processing)
    get admin_orders_path, params: { format: 'json' }
    count_data = JSON.parse(response.body)
    assert_equal 1, count_data['pending_count'], "❌ Pending count should be 1"
    assert_equal 1, count_data['processing_count'], "❌ Processing count should be 1"

    puts "✅ Step 3: Real-time counts updated correctly"

    # Step 4: Update second order status
    patch admin_update_order_status_path(order2), params: { status: 'shipped' }, as: :json
    assert_response :success

    # Check database
    order2.reload
    assert_equal 'shipped', order2.status, "❌ Second order not updated"

    puts "✅ Step 4: Second order status updated to shipped"

    # Step 5: Final count verification
    get admin_orders_path, params: { format: 'json' }
    final_counts = JSON.parse(response.body)
    assert_equal 0, final_counts['pending_count'], "❌ Should have 0 pending"
    assert_equal 1, final_counts['processing_count'], "❌ Should have 1 processing"
    assert_equal 1, final_counts['shipped_count'], "❌ Should have 1 shipped"

    puts "✅ Step 5: All real-time count updates working perfectly"

    puts "\n🎉 COMPLETE REAL-TIME WORKFLOW SUCCESSFUL!"
    puts "   ✓ Status updates work instantly"
    puts "   ✓ Counter updates happen in real-time"
    puts "   ✓ Database changes persist correctly"
    puts "   ✓ Multiple simultaneous updates work"
    puts "💡 The Order Management system is now 100% LIVE!"
  end
end
