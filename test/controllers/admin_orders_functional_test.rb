require "test_helper"

class AdminOrdersFunctionalTest < ActionDispatch::IntegrationTest
  ## 🔍 END-TO-END TESTING OF ADMIN ORDERS FUNCTIONALITY ##

  setup do
    # Clean database state
    Order.destroy_all
    Admin.destroy_all

    # Create fresh admin
    @admin = Admin.create!(email: 'test@admin.com', password: 'password123', password_confirmation: 'password123')

    # Create fresh orders
    @pending = Order.create!(full_name: 'John Pending', email: 'john@pending.com', phone: '+1234567890', country_code: 'US', city: 'New York', state: 'NY', postal_code: '10001', address: '123 St', quantity: 1, status: :pending, translation: 'english')
    @processing = Order.create!(full_name: 'Jane Processing', email: 'jane@processing.com', phone: '+1987654321', country_code: 'US', city: 'LA', state: 'CA', postal_code: '90210', address: '456 St', quantity: 1, status: :processing, translation: 'english')

    # Sign in
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
  end

  test "🤖 End-to-end status update workflow" do
    puts "=== TESTING COMPLETE STATUS UPDATE WORKFLOW ==="

    # 1. Check initial page loads correctly
    get admin_orders_path
    assert_response :success
    assert response.body.include?('John Pending'), "Should show pending order"
    assert response.body.include?('Jane Processing'), "Should show processing order"

    # 2. Test AJAX filtering (filter for pending only)
    get admin_orders_path, params: { status: 'pending', format: 'json' }
    assert_response :success

    filter_data = JSON.parse(response.body)
    assert_equal 1, filter_data['pending_count'], "Should have 1 pending order"
    assert filter_data['html'].include?('John Pending'), "Should show John Pending"
    refute filter_data['html'].include?('Jane Processing'), "Should NOT show Jane Processing"

    puts "✅ AJAX filtering works"

    # 3. Test status update via AJAX
    patch admin_update_order_status_path(@pending), params: { status: 'processing' }, as: :json
    assert_response :success

    update_data = JSON.parse(response.body)
    assert update_data['success'], "Status update should succeed"
    assert_equal 'processing', update_data['new_status'], "New status should be processing"

    @pending.reload
    assert_equal 'processing', @pending.status.to_s, "Database should be updated"

    puts "✅ AJAX status update works"

    # 4. Test that counts update correctly
    get admin_orders_path
    assert_response :success

    # Should now have 0 pending, 2 processing
    assert response.body.include?('<h3 class="text-2xl font-bold text-red-600" id="pending-count">0</h3>'), "Pending count should be 0"
    assert response.body.include?('<h3 class="text-2xl font-bold text-yellow-600" id="processing-count">2</h3>'), "Processing count should be 2"

    puts "✅ Status counts update correctly"

    # 5. Test filtering after status change
    get admin_orders_path, params: { status: 'processing', format: 'json' }
    assert_response :success

    filter_after_data = JSON.parse(response.body)
    assert_equal 2, filter_after_data['processing_count'], "Should show 2 processing orders"
    assert filter_after_data['html'].include?('John Pending'), "Should show John (now processing)"
    assert filter_after_data['html'].include?('Jane Processing'), "Should show Jane"

    puts "✅ Filtering works after status updates"

    puts "🎉 ALL WORKFLOW TESTS PASSED!"
  end
end
