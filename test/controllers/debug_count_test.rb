require "test_helper"

class DebugCountTest < ActionDispatch::IntegrationTest
  ## DEBUG TEST TO SEE WHY COUNTS SHOW 0 ##

  setup do
    # Clean everything
    Order.destroy_all
    Admin.destroy_all

    # Create admin
    @admin = Admin.create!(email: 'debug@test.com', password: 'password123', password_confirmation: 'password123')

    # Sign in
    post admin_session_path, params: { admin: { email: @admin.email, password: 'password123' } }
    follow_redirect!
  end

  test "debug status counts" do
    # Create test orders
    Order.create!(
      full_name: 'Pending Order',
      email: 'pending@test.com',
      phone: '+1234567890',
      country_code: 'US',
      city: 'NY', state: 'NY', postal_code: '10001', address: '123 St',
      quantity: 1, status: :pending, translation: 'english'
    )

    Order.create!(
      full_name: 'Processing Order',
      email: 'processing@test.com',
      phone: '+1234567891',
      country_code: 'US',
      city: 'CA', state: 'CA', postal_code: '90210', address: '456 St',
      quantity: 1, status: :processing, translation: 'english'
    )

    # Debug what the actual status values are
    Order.all.each do |order|
      puts "Order #{order.id}: status = #{order.status.inspect} (type: #{order.status.class})"
      puts "Order #{order.id}: status_before_type_cast = #{order.status_before_type_cast.inspect}"
    end

    # Debug enum values
    puts "Order.statuses = #{Order.statuses.inspect}"

    # Debug the different ways to count
    pending_count_1 = Order.where(status: :pending).count
    pending_count_2 = Order.where(status: 'pending').count
    pending_count_3 = Order.where(status: Order.statuses[:pending]).count
    pending_count_4 = Order.where(status: Order.statuses['pending']).count

    puts "Counting pending orders:"
    puts "where(status: :pending) = #{pending_count_1}"
    puts "where(status: 'pending') = #{pending_count_2}"
    puts "where(status: Order.statuses[:pending]) = #{pending_count_3}"
    puts "where(status: Order.statuses['pending']) = #{pending_count_4}"

    # Test controller logic
    get admin_orders_path
    assert_equal 1, Order.where(status: Order.statuses[:pending]).count, "Should have 1 pending order"
    assert_equal 1, Order.where(status: Order.statuses[:processing]).count, "Should have 1 processing order"
  end
end
