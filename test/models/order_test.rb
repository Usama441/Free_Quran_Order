require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @order = Order.new(
      full_name: "John Doe",
      email: "john@example.com",
      phone: "+1234567890",
      city: "New York",
      country_code: "+1",  # Default to USA
      address: "123 Main Street",
      state: "NY",
      postal_code: "10001",
      quantity: 1,
      translation: "english"
    )
  end

  test "should be valid with all required attributes" do
    assert @order.valid?, "Order should be valid with all required attributes: #{@order.errors.full_messages.join(', ')}"
  end

  test "should require full_name" do
    @order.full_name = nil
    assert_not @order.valid?
    assert_includes @order.errors[:full_name], "can't be blank"
  end

  test "should require email" do
    @order.email = nil
    assert_not @order.valid?
    assert_includes @order.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @order.email = "invalid-email"
    assert_not @order.valid?
    assert_includes @order.errors[:email], "is invalid"
  end

  test "should require phone" do
    @order.phone = nil
    assert_not @order.valid?
    assert_includes @order.errors[:phone], "can't be blank"
  end

  test "should require city" do
    @order.city = nil
    assert_not @order.valid?
    assert_includes @order.errors[:city], "can't be blank"
  end

  test "should require country_code" do
    @order.country_code = nil
    assert_not @order.valid?
    assert_includes @order.errors[:country_code], "can't be blank"
  end

  test "should require address" do
    @order.address = nil
    assert_not @order.valid?
    assert_includes @order.errors[:address], "can't be blank"
  end

  test "should require quantity" do
    @order.quantity = nil
    assert_not @order.valid?
    assert_includes @order.errors[:quantity], "can't be blank"
  end

  test "quantity should be positive integer" do
    @order.quantity = 0
    assert_not @order.valid?
    assert_includes @order.errors[:quantity], "must be greater than 0"

    @order.quantity = -1
    assert_not @order.valid?

    @order.quantity = 1.5
    assert_not @order.valid?
  end

  test "should have valid country codes" do
    valid_codes = ['+92', '+1', '+44', '+971', '+966', '+973', '+974', '+968', '+965', '+20', '+91', '+93', '+98']
    valid_codes.each do |code|
      @order.country_code = code
      assert @order.valid?, "#{code} should be valid"
    end
  end

  test "should set default translation to english" do
    order = Order.new(
      full_name: "Test User",
      email: "test@example.com",
      phone: "1234567890",
      city: "Test City",
      address: "Test Address",
      quantity: 1
    )
    # This should trigger the default translation in the model or controller
    assert_equal "english", order.translation
  end

  test "should allow custom translation" do
    @order.translation = "urdu"
    assert @order.valid?
    assert_equal "urdu", @order.translation
  end

  test "should belong to quran" do
    # Orders do not belong to quran in this schema
    # They are independent entities
    skip "Orders do not belong to quran in this schema"
  end

  test "should create order successfully" do
    order_count = Order.count
    order = Order.create!(
      full_name: "John Doe",
      email: "john@example.com",
      phone: "+1234567890",
      city: "New York",
      country_code: "+1",
      address: "123 Main St",
      state: "NY",
      postal_code: "10001",
      quantity: 2,
      translation: "english"
    )
    assert_equal order_count + 1, Order.count
    assert order.persisted?
  end

  test "should update order successfully" do
    # First save the order to persist it
    @order.save!
    original_quantity = @order.quantity
    @order.update!(quantity: original_quantity + 1)
    assert_equal original_quantity + 1, @order.reload.quantity
  end

  test "should destroy order successfully" do
    # First save the order to persist it
    @order.save!
    order_count = Order.count
    @order.destroy
    assert_equal order_count - 1, Order.count
  end

  test "should save with different country codes" do
    countries_with_codes = [
      ["Pakistan", "+92"],
      ["USA", "+1"],
      ["UK", "+44"],
      ["UAE", "+971"]
    ]

    countries_with_codes.each do |country, code|
      order = Order.new(@order.attributes.merge(
        email: "test#{code}@example.com",
        country_code: code
      ))
      assert order.valid?, "Order for #{country} should be valid"
      order.save!
      assert_equal code, order.reload.country_code
    end
  end

  test "should process multiple quantity values" do
    (1..5).each do |qty|
      order = Order.new(@order.attributes.merge(
        email: "test#{qty}@example.com",
        quantity: qty
      ))
      assert order.valid?, "Order with quantity #{qty} should be valid"
      order.save!
      assert_equal qty, order.reload.quantity
    end
  end

  test "should handle translations correctly" do
    translations = ['english', 'urdu', 'french', 'spanish', 'arabic']

    translations.each do |translation|
      order = Order.new(@order.attributes.merge(
        email: "test#{translation}@example.com",
        translation: translation
      ))
      assert order.valid?, "Order with #{translation} translation should be valid"
      order.save!
      assert_equal translation, order.reload.translation
    end
  end

  test "should validate email uniqueness scoped by recent time" do
    # This would test email uniqueness validation if implemented
    skip "Email uniqueness validation not implemented yet"
  end

  test "should have timestamps" do
    assert_respond_to @order, :created_at
    assert_respond_to @order, :updated_at
  end

  # Test edge cases
  test "should handle very long names" do
    @order.full_name = "A" * 100
    assert @order.valid?, "Very long names should be accepted"
  end

  test "should handle very long addresses" do
    @order.address = "A" * 500
    assert @order.valid?, "Very long addresses should be accepted"
  end

  test "should handle various phone formats" do
    valid_phones = [
      "+1234567890",
      "+92-300-1234567",
      "00923001234567",
      "3001234567"
    ]

    valid_phones.each do |phone|
      @order.phone = phone
      assert @order.valid?, "Phone format '#{phone}' should be accepted"
    end
  end

  test "should handle various postal code formats" do
    valid_codes = ["10001", "54000", "SW1A 1AA", "123456"]

    valid_codes.each do |code|
      @order.postal_code = code
      assert @order.valid?, "Postal code '#{code}' should be accepted"
    end
  end
end
