require "test_helper"

class UIUnitTest < ActionDispatch::IntegrationTest
  ## 🔍 COMPREHENSIVE UI UNIT TESTING OF ORDER MANAGEMENT ##
  ## ✅ CHECKING IF HTML ELEMENTS ARE DYNAMICALLY CONNECTED TO DATABASE ##

  setup do
    # Clear data for clean tests
    Order.destroy_all
    Admin.destroy_all
    Quran.destroy_all

    # Create admin
    @admin = Admin.create!(email: 'ui@test.com', password: 'password123', password_confirmation: 'password123')

    # Create Quran for association
    @quran = Quran.create!(title: "UI Test Quran", writer: "Test Author", translation: "english", pages: 604, stock: 100)

    # Create various order states to test UI rendering
    @pending_order = Order.create!(
      full_name: 'John Pending', email: 'john@pending.com', phone: '+1234567890',
      country_code: 'US', city: 'New York', state: 'NY', postal_code: '10001', address: '123 St',
      quantity: 2, status: :pending, translation: 'english', quran: @quran
    )

    @processing_order = Order.create!(
      full_name: 'Jane Processing', email: 'jane@processing.com', phone: '+1987654321',
      country_code: 'Canada', city: 'Toronto', state: 'ON', postal_code: 'M5V', address: '456 St',
      quantity: 1, status: :processing, translation: 'english', quran: @quran
    )

    @shipped_order = Order.create!(
      full_name: 'Bob Shipped', email: 'bob@shipped.com', phone: '+1555123456',
      country_code: 'UK', city: 'London', state: 'London', postal_code: 'SW1A', address: '789 St',
      quantity: 3, status: :shipped, translation: 'english', quran: @quran
    )

    @delivered_order = Order.create!(
      full_name: 'Alice Delivered', email: 'alice@delivered.com', phone: '+1202987654',
      country_code: 'Australia', city: 'Sydney', state: 'NSW', postal_code: '2000', address: '101 St',
      quantity: 1, status: :delivered, translation: 'english', quran: @quran
    )

    # Sign in admin
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
  end

  test "🧪 UI Elements Connect to Database - Status Counters" do
    puts "=== TESTING STATUS COUNTERS CONNECTIVITY ==="
    get admin_orders_path

    # ✅ TEST: Check if status counters display correct database counts
    assert response.body.include?('<h3 class="text-2xl font-bold text-red-600" id="pending-count">1</h3>'), "❌ Pending count not connected to database"
    assert response.body.include?('<h3 class="text-2xl font-bold text-yellow-600" id="processing-count">1</h3>'), "❌ Processing count not connected to database"
    assert response.body.include?('<h3 class="text-2xl font-bold text-blue-600" id="shipped-count">1</h3>'), "❌ Shipped count not connected to database"
    assert response.body.include?('<h3 class="text-2xl font-bold text-green-600" id="delivered-count">1</h3>'), "❌ Delivered count not connected to database"

    puts "✅ All status counters correctly display database counts!"
  end

  test "🧪 UI Elements Connect to Database - Order Table Rendering" do
    puts "=== TESTING ORDER TABLE DATABASE CONNECTIVITY ==="
    get admin_orders_path

    # ✅ TEST: Check if orders are dynamically loaded from database
    assert response.body.include?('John Pending'), "❌ Pending order name not rendered from database"
    assert response.body.include?('Jane Processing'), "❌ Processing order name not rendered from database"
    assert response.body.include?('Bob Shipped'), "❌ Shipped order name not rendered from database"
    assert response.body.include?('Alice Delivered'), "❌ Delivered order name not rendered from database"

    # ✅ TEST: Check if order details are correctly displayed
    assert response.body.include?('john@pending.com'), "❌ Email not rendered from database"
    assert response.body.include?('+1234567890'), "❌ Phone not rendered from database"
    assert response.body.include?('New York'), "❌ City not rendered from database"
    assert response.body.include?('UK'), "❌ Country code not rendered from database"
    assert response.body.include?('UI Test Quran'), "❌ Quran title not rendered from database"

    # ✅ TEST: Check if quantities are displayed correctly
    assert response.body.include?('2 copies'), "❌ Quantity '2 copies' not rendered from database"
    assert response.body.include?('1 copy'), "❌ Quantity '1 copy' not rendered from database"
    assert response.body.include?('3 copies'), "❌ Quantity '3 copies' not rendered from database"

    puts "✅ All order data correctly rendered from database!"
  end

  test "🧪 UI Elements Connect to Database - Status Badges" do
    puts "=== TESTING STATUS BADGES DATABASE CONNECTIVITY ==="
    get admin_orders_path

    # ✅ TEST: Check if status badges show correct colors based on database status
    # Red badges for pending
    assert response.body.include?('bg-red-100 text-red-800'), "❌ Red badge not showing for pending status from database"
    # Yellow badges for processing
    assert response.body.include?('bg-yellow-100 text-yellow-800'), "❌ Yellow badge not showing for processing status from database"
    # Blue badges for shipped
    assert response.body.include?('bg-blue-100 text-blue-800'), "❌ Blue badge not showing for shipped status from database"
    # Green badges for delivered
    assert response.body.include?('bg-green-100 text-green-800'), "❌ Green badge not showing for delivered status from database"

    # ✅ TEST: Check if status text is correct
    assert response.body.include?('Pending'), "❌ 'Pending' text not rendered from database enum"
    assert response.body.include?('Processing'), "❌ 'Processing' text not rendered from database enum"
    assert response.body.include?('Shipped'), "❌ 'Shipped' text not rendered from database enum"
    assert response.body.include?('Delivered'), "❌ 'Delivered' text not rendered from database enum"

    puts "✅ All status badges correctly connected to database enum values!"
  end

  test "🧪 UI Elements Connect to Database - Order Dates" do
    puts "=== TESTING ORDER DATES DATABASE CONNECTIVITY ==="
    get admin_orders_path

    # Get the formatted dates from orders
    recent_date = @pending_order.created_at.strftime('%b %d, %Y')

    # ✅ TEST: Check if dates are formatted and displayed
    assert response.body.include?('Oct 17, 2025'), "❌ Order created date not formatted from database"
    assert response.body.include?(recent_date), "❌ Dynamic date not rendered from created_at database field"

    puts "✅ Order dates correctly formatted and displayed from database!"
  end

  test "🧪 UI Elements Connect to Database - Ajax Filtering Elements" do
    puts "=== TESTING AJAX FILTERING UI ELEMENTS ==="
    get admin_orders_path

    # ✅ TEST: Check if filter dropdowns exist and are connected
    assert response.body.include?('<select id="status-filter"'), "❌ Status filter dropdown not present"
    assert response.body.include?('<input type="date" id="start-date-filter"'), "❌ Start date filter not present"
    assert response.body.include?('<input type="date" id="end-date-filter"'), "❌ End date filter not present"

    # ✅ TEST: Check if filter buttons exist
    assert response.body.include?('Filter</span>'), "❌ Filter button not present"
    assert response.body.include?('Clear</span>'), "❌ Clear button not present"

    # ✅ TEST: Check if JavaScript functions are present for AJAX
    assert response.body.include?('function filterOrders()'), "❌ filterOrders JavaScript function not present"
    assert response.body.include?('function clearFilters()'), "❌ clearFilters JavaScript function not present"
    assert response.body.include?('/admin/orders?'), "❌ AJAX URL not configured correctly"

    puts "✅ All AJAX filter elements present and connected!"
  end

  test "🧪 UI Elements Connect to Database - Status Dropdowns" do
    puts "=== TESTING STATUS DROPDOWN CONNECTIVITY ==="
    get admin_orders_path

    # ✅ TEST: Check if dropdown onchange calls correct function
    assert response.body.include?('onchange="updateOrderStatus('), "❌ Status dropdown not connected to updateOrderStatus function"
    assert response.body.include?('this.value'), "❌ Dropdown value not passed to JavaScript function"

    # ✅ TEST: Check if JavaScript function exists
    assert response.body.include?('function updateOrderStatus(orderId, newStatus)'), "❌ updateOrderStatus function not present"

    puts "✅ Status dropdowns correctly connected to AJAX update functions!"
  end

  test "🧪 UI Elements Connect to Database - Dynamic Table Container" do
    puts "=== TESTING DYNAMIC TABLE CONTAINER ==="
    get admin_orders_path

    # ✅ TEST: Check if orders table container has correct ID for AJAX updates
    assert response.body.include?('id="orders-table-container"'), "❌ Orders table container not present with correct ID"
    assert response.body.include?('<%= render \'orders_table\' %>'), "❌ Partial render not connected to database"

    puts "✅ Dynamic table container correctly set up for AJAX updates!"
  end

  test "🧪 DATABASE CONNECTIVITY - All UI Elements Connected" do
    puts "=== FINAL DATABASE CONNECTIVITY VERIFICATION ==="
    get admin_orders_path

    # Summary test of all database connections
    connected_elements = 0
    total_elements = 0

    # Check status counters connection
    total_elements += 1
    connected_elements += 1 if response.body.include?('id="pending-count">1</h3>')

    # Check order data rendering
    total_elements += 1
    connected_elements += 1 if response.body.include?('John Pending') && response.body.include?('Toronto')

    # Check status badges
    total_elements += 1
    connected_elements += 1 if response.body.include?('bg-red-100') && response.body.include?('bg-green-100')

    # Check AJAX elements
    total_elements += 1
    connected_elements += 1 if response.body.include?('filterOrders()') && response.body.include?('updateOrderStatus(')

    # Check table data
    total_elements += 1
    connected_elements += 1 if response.body.include?('419 total orders') && response.body.include?('UI Test Quran')

    percentage = (connected_elements.to_f / total_elements * 100).round(1)

    puts "🔗 DATABASE CONNECTIVITY: #{connected_elements}/#{total_elements} UI elements (#{percentage}%)"
    puts "✅ RESULT: #{connected_elements == total_elements ? 'ALL UI ELEMENTS CONNECTED!' : 'Some elements not connected!'}"

    assert_equal total_elements, connected_elements, "Not all UI elements connected to database!"
  end
end
