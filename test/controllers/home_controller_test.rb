require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Don't load seeds in test
  end

  test "should get home page" do
    get root_path
    assert_response :success
    assert_select "title", "Free Quran Distribution"
    assert_select "h2", "Receive a Free Copy of the Holy Quran"
  end

  test "should display available qurans section" do
    get root_path
    assert_response :success
    assert_select "h3", "Available Qurans"
  end

  test "should show qurans from database when available" do
    # Create a test quran
    quran = Quran.create!(
      title: "Test Quran",
      writer: "Test Author",
      translation: "english",
      pages: 500,
      stock: 50
    )

    get root_path
    assert_response :success
    assert_select ".grid .rounded-xl", minimum: 1
  end

  test "should show fallback qurans when database is empty" do
    # Ensure no qurans in database
    Quran.destroy_all

    get root_path
    assert_response :success
    assert_select ".grid .rounded-xl", minimum: 3  # Should show fallback cards
  end

  test "should display quran information correctly" do
    quran = Quran.create!(
      title: "English Quran",
      writer: "Dr. Khan",
      translation: "english",
      pages: 604,
      stock: 100,
      description: "Complete English translation"
    )

    get root_path
    assert_response :success
    assert_match CGI.escapeHTML(quran.title), response.body
    assert_match CGI.escapeHTML(quran.writer), response.body
    assert_match "604", response.body  # pages
    assert_match "100", response.body  # stock
  end

  test "should include image carousel functionality" do
    get root_path
    assert_response :success
    assert_match "initializeCarousel", response.body
    assert_match "changeSlide", response.body
  end

  test "should have order now links" do
    get root_path
    assert_response :success
    assert_select "a", text: "Order Now", minimum: 1
  end

  test "should not show qurans with zero stock" do
    Quran.create!(
      title: "Out of Stock Quran",
      writer: "Test Author",
      translation: "english",
      pages: 500,
      stock: 0
    )

    in_stock_quran = Quran.create!(
      title: "In Stock Quran",
      writer: "Test Author",
      translation: "english",
      pages: 500,
      stock: 10
    )

    get root_path
    assert_response :success
    assert_match CGI.escapeHTML(in_stock_quran.title), response.body
    refute_match CGI.escapeHTML("Out of Stock Quran"), response.body
  end

  test "should handle non-existent routes" do
    assert_raises(ActionController::RoutingError) do
      get "/non-existent-page"
    end
  end

  test "should include CSS and JavaScript assets" do
    get root_path
    assert_response :success
    assert_match "cdn.tailwindcss.com", response.body
  end

  test "home page should be accessible without authentication" do
    get root_path
    assert_response :success
    assert_not_redirected_to admin_sessions_new_path
  end
end
