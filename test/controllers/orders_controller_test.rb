require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Test without creating Quran to avoid ActiveStorage issues
  end

  test "should get new order form" do
    get new_order_path
    assert_response :success
    assert_select "title", text: /Order Free Quran/i
    assert_select "form[id='order-form']"
  end

  test "should create order successfully with valid data via HTML form" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "+1",
        address: "123 Main Street",
        state: "NY",
        postal_code: "10001",
        quantity: 1,
        translation: "english"
      }
    }

    assert_difference('Order.count') do
      post orders_path, params: order_params
    end

    assert_redirected_to "/orders/create"
    follow_redirect!
    assert_match "Thank you", response.body
  end

  test "should create order successfully with valid data via JSON AJAX" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "+1",
        address: "123 Main Street",
        state: "NY",
        postal_code: "10001",
        quantity: 1,
        translation: "english"
      }
    }

    assert_difference('Order.count') do
      post orders_path(format: :json), params: order_params
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response['success']
    assert_match "Order submitted successfully!", json_response['message']
  end

  test "should not create order with invalid data" do
    order_params = {
      order: {
        full_name: "",  # Missing required field
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 1,
        translation: "english"
      }
    }

    assert_no_difference('Order.count') do
      post orders_path, params: order_params
    end

    assert_response :unprocessable_entity
    assert_select ".bg-red-50", text: "Please fix the following errors"
  end

  test "should require all essential fields" do
    required_fields = [:full_name, :email, :phone, :city, :address]

    required_fields.each do |field|
      order_params = {
        order: {
          full_name: "John Doe",
          email: "john@example.com",
          phone: "+1234567890",
          city: "New York",
          country_code: "US",
          address: "123 Main Street",
          quantity: 1,
          translation: "english"
        }
      }
      order_params[:order][field] = ""  # Set field to empty

      post orders_path, params: order_params
      assert_response :unprocessable_entity
      assert_select ".bg-red-50"
    end
  end

  test "should validate email format" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "invalid-email-format",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 1,
        translation: "english"
      }
    }

    post orders_path, params: order_params
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  test "should validate quantity is positive" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 0,  # Invalid quantity
        translation: "english"
      }
    }

    post orders_path, params: order_params
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  test "should set default translation to english" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 1
        # No translation specified - should default to 'english'
      }
    }

    post orders_path, params: order_params
    assert_redirected_to "/orders/create"

    created_order = Order.last
    assert_equal "english", created_order.translation
  end

  test "should accept custom translations" do
    ["urdu", "french", "spanish", "arabic"].each do |translation|
      order_params = {
        order: {
          full_name: "John Doe",
          email: "john#{translation}@example.com",
          phone: "+1234567890",
          city: "New York",
          country_code: "US",
          address: "123 Main Street",
          quantity: 1,
          translation: translation
        }
      }

      post orders_path, params: order_params
      assert_redirected_to "/orders/create"

      created_order = Order.last
      assert_equal translation, created_order.translation
    end
  end

  test "should accept different country codes" do
    valid_countries = ['PK', 'US', 'GB', 'AE', 'SA', 'CA', 'IN', 'BD']

    valid_countries.each do |country|
      order_params = {
        order: {
          full_name: "John Doe",
          email: "john#{country}@example.com",
          phone: "+1234567890",
          city: "Test City",
          country_code: country,
          address: "123 Main Street",
          quantity: 1,
          translation: "english"
        }
      }

      post orders_path, params: order_params
      assert_redirected_to "/orders/create"
    end
  end

  test "should show success page after order creation" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 1,
        translation: "english"
      }
    }

    post orders_path, params: order_params
    assert_redirected_to "/orders/create"

    follow_redirect!
    assert_response :success
    assert_select "h2", text: /Thank you/i
  end

  test "success page should display order details" do
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 2,
        translation: "english"
      }
    }

    post orders_path, params: order_params
    follow_redirect!

    assert_response :success
    assert_match "John Doe", response.body
    assert_match "New York", response.body
    assert_match "US", response.body
    assert_match "2", response.body  # quantity
  end

  test "should handle GET request to create page" do
    get "/orders/create"
    assert_response :success
  end

  test "should store phone number correctly" do
    phone = "+1-555-123-4567"
    order_params = {
      order: {
        full_name: "John Doe",
        email: "john@example.com",
        phone: phone,
        city: "New York",
        country_code: "US",
        address: "123 Main Street",
        quantity: 1,
        translation: "english"
      }
    }

    post orders_path, params: order_params
    follow_redirect!

    created_order = Order.last
    assert_equal phone, created_order.phone
  end
end
