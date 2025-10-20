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

  test "DEBUG: Frontend JavaScript simulation" do
    puts "=== DEBUGGING FRONTEND SIMULATION ==="
    get admin_orders_path

    # Check if JavaScript functions exist
    has_dropdown = response.body.include?('onchange="updateOrderStatus(')
    has_function = response.body.include?('function updateOrderStatus(')
    has_update_counts = response.body.include?('function updateCounts(')

    puts "Has dropdown onchange handler?: #{has_dropdown}"
    puts "JavaScript function exists?: #{has_function}"
    puts "Update counts function exists?: #{has_update_counts}"

    # Check for order data in HTML
    has_order_data = response.body.include?('Test User')
    has_order_id = response.body.include?("updateOrderStatus(#{@order.id}")
    puts "Order data rendered in HTML?: #{has_order_data}"
    puts "Order ID #{@order.id} in HTML?: #{has_order_id}"

    # Check status badge
    has_badge = response.body.include?('bg-red-100 text-red-800')
    puts "Status badge classes present?: #{has_badge}"

    puts "=== FRONTEND DEBUG COMPLETE ==="
  end
end
