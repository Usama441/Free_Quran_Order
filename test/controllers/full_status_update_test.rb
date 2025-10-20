require "test_helper"

class FullStatusUpdateTest < ActionDispatch::IntegrationTest
  ## 🎯 COMPLETE END-TO-END STATUS UPDATE TESTING ##
  ## TESTING THE WHOLE USER WORKFLOW FROM FRONTEND TO DATABASE ##

  setup do
    # Create test data
    Order.destroy_all
    Admin.destroy_all
    Quran.destroy_all

    @admin = Admin.create!(email: 'admin@test.com', password: 'password123', password_confirmation: 'password123')
    @quran = Quran.create!(title: "Test Mushaf", writer: "Test Author", translation: "english", pages: 500, stock: 200)

    @order = Order.new(
      full_name: 'Alice Johnson',
      email: 'alice@test.com',
      phone: '+19876543210',
      country_code: 'US',
      city: 'Detroit',
      state: 'MI',
      postal_code: '48201',
      address: '123 Main St',
      quantity: 1,
      status: :pending,
      translation: 'english'
    )
    @order.quran = @quran
    @order.save!

    puts "🧪 SETUP COMPLETE: Order ID: #{@order.id} - Initial status: #{@order.status}"
  end

  test "🔄 COMPLETE STATUS UPDATE WORKFLOW - pending → processing → shipped → delivered" do
    puts "=== TESTING COMPLETE STATUS UPDATE WORKFLOW ==="
    
    # Step 1: Sign in as admin
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
    assert_response :success
    puts "✅ Step 1: Admin signed in successfully"

    # Step 2: Load orders page and check initial state
    get admin_orders_path
    assert_response :success

    # Check initial order is displayed
    assert response.body.include?('Alice Johnson'), "❌ Order not displayed on page"
    assert response.body.include?('<option value="pending" selected'), "❌ Initial status not set correctly"
    assert response.body.include?('bg-red-100 text-red-800'), "❌ Initial status badge not red"

    # Check initial counts (should have 1 pending, 0 others)
    assert response.body.include?('<h3 class="text-2xl font-bold text-red-600" id="pending-count">1</h3>'), "❌ Pending count not 1"
    assert response.body.include?('<h3 class="text-2xl font-bold text-yellow-600" id="processing-count">0</h3>'), "❌ Processing count not 0"
    
    puts "✅ Step 2: Initial page state correct"

    # Step 3: Update status from pending to processing via backend
    patch admin_update_order_status_path(@order), params: { status: 'processing' }, as: :json

    # Check backend response
    assert_response :success
    response_data = JSON.parse(response.body)
    assert response_data['success'], "❌ Backend update failed"
    assert_equal 'processing', response_data['new_status'], "❌ Backend returned wrong status"

    puts "✅ Step 3: Backend status update successful"

    # Step 4: Verify database was updated
    @order.reload
    assert_equal 'processing', @order.status, "❌ Database not updated by backend"

    puts "✅ Step 4: Database updated correctly"

    # Step 5: Check that frontend would get updated counts
    get admin_orders_path, params: { format: 'json' }
    assert_response :success
    count_data = JSON.parse(response.body)
    assert_equal 1, count_data['processing_count'], "❌ Frontend count data wrong for processing"
    assert_equal 0, count_data['pending_count'], "❌ Frontend count data wrong for pending"

    puts "✅ Step 5: Frontend gets correct count updates"

    # Step 6: Update to shipped
    patch admin_update_order_status_path(@order), params: { status: 'shipped' }, as: :json
    assert_response :success
    
    @order.reload
    assert_equal 'shipped', @order.status, "❌ Status not updated to shipped"
    
    puts "✅ Step 6: Status updated to shipped"

    # Step 7: Update to delivered
    patch admin_update_order_status_path(@order), params: { status: 'delivered' }, as: :json
    assert_response :success
    
    @order.reload
    assert_equal 'delivered', @order.status, "❌ Status not updated to delivered"
    
    puts "✅ Step 7: Status updated to delivered (final)"

    # Step 8: Final count verification
    get admin_orders_path, params: { format: 'json' }
    assert_response :success
    final_data = JSON.parse(response.body)
    assert_equal 0, final_data['pending_count'], "❌ Final pending count wrong"
    assert_equal 0, final_data['processing_count'], "❌ Final processing count wrong"
    assert_equal 0, final_data['shipped_count'], "❌ Final shipped count wrong"
    assert_equal 1, final_data['delivered_count'], "❌ Final delivered count wrong"

    puts "✅ Step 8: All final counts correct"

    puts "🎉 COMPLETE WORKFLOW SUCCESS: pending → processing → shipped → delivered"
    puts "🔄 Status updates, database persistence, and UI counting all working!"
  end

  test "🎨 UI BADGE COLOR CHANGES - Testing Visual Feedback" do
    puts "=== TESTING UI BADGE COLOR CHANGES ==="

    # Sign in
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!

    # Test each status color change
    status_colors = {
      'pending' => 'bg-red-100 text-red-800',
      'processing' => 'bg-yellow-100 text-yellow-800', 
      'shipped' => 'bg-blue-100 text-blue-800',
      'delivered' => 'bg-green-100 text-green-800'
    }

    status_colors.each do |status, expected_classes|
      # Update order to this status
      patch admin_update_order_status_path(@order), params: { status: status }, as: :json
      assert_response :success
      
      # Load page and check the badge classes are displayed
      get admin_orders_path
      assert response.body.include?(expected_classes), 
             "❌ Badge classes '#{expected_classes}' not found for status '#{status}'"
      
      puts "✅ Badge color correct for #{status}: #{expected_classes}"
    end

    puts "✅ All status badge colors working correctly"
  end

  test "📊 FILTER FUNCTIONALITY - Testing AJAX Filtering" do
    puts "=== TESTING AJAX FILTERING === "

    # Create multiple orders with different statuses for filtering
    order2 = Order.create!(
      full_name: 'Bob Smith', email: 'bob@test.com', phone: '+11234567890',
      country_code: 'US', city: 'Chicago', state: 'IL', postal_code: '60601',
      address: '456 Oak St', quantity: 2, status: :processing, translation: 'english'
    )
    order2.quran = @quran
    order2.save!

    # Sign in
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!

    # Test filtering by status=pending
    get admin_orders_path, params: { status: 'pending', format: 'json' }
    assert_response :success
    filter_data = JSON.parse(response.body)
    
    assert_equal 1, filter_data['pending_count'], "❌ Pending filter wrong count"
    assert filter_data['html'].include?('Alice Johnson'), "❌ Pending filter missing Alice"
    refute filter_data['html'].include?('Bob Smith'), "❌ Pending filter incorrectly showing Bob"

    puts "✅ Pending status filter working correctly"

    # Test filtering by status=processing
    get admin_orders_path, params: { status: 'processing', format: 'json' }
    assert_response :success
    filter_data2 = JSON.parse(response.body)
    
    assert_equal 1, filter_data2['processing_count'], "❌ Processing filter wrong count"
    assert filter_data2['html'].include?('Bob Smith'), "❌ Processing filter missing Bob"
    refute filter_data2['html'].include?('Alice Johnson'), "❌ Processing filter incorrectly showing Alice"

    puts "✅ Processing status filter working correctly"

    puts "✅ AJAX filtering fully functional"
  end
end
