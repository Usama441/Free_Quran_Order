require "test_helper"

class QuranTest < ActiveSupport::TestCase
  # Fixtures will be used if available, otherwise create test data
  setup do
    @quran = Quran.new(
      title: "Test Quran",
      writer: "Test Author",
      translation: "english",
      pages: 604,
      stock: 100,
      description: "A comprehensive test Quran"
    )
  end

  # Validations Tests
  test "should be valid with all required attributes" do
    assert @quran.valid?, "Quran should be valid with all required attributes: #{@quran.errors.full_messages.join(', ')}"
  end

  test "should require title" do
    @quran.title = nil
    assert_not @quran.valid?
    assert_includes @quran.errors[:title], "can't be blank"
  end

  test "should require unique title" do
    @quran.save!
    duplicate_quran = @quran.dup
    assert_not duplicate_quran.valid?
    assert_includes duplicate_quran.errors[:title], "has already been taken"
  end

  test "should require writer" do
    @quran.writer = nil
    assert_not @quran.valid?
    assert_includes @quran.errors[:writer], "can't be blank"
  end

  test "should require translation" do
    @quran.translation = nil
    assert_not @quran.valid?
    assert_includes @quran.errors[:translation], "can't be blank"
  end

  test "should require pages" do
    @quran.pages = nil
    assert_not @quran.valid?
    assert_includes @quran.errors[:pages], "can't be blank"
  end

  test "pages should be a positive integer" do
    @quran.pages = 0
    assert_not @quran.valid?
    assert_includes @quran.errors[:pages], "must be greater than 0"

    @quran.pages = -1
    assert_not @quran.valid?
    assert_includes @quran.errors[:pages], "must be greater than 0"

    @quran.pages = 1.5
    assert_not @quran.valid?
  end

  test "should require stock" do
    @quran.stock = nil
    assert_not @quran.valid?
    assert_includes @quran.errors[:stock], "can't be blank"
  end

  test "stock should not be negative" do
    @quran.stock = -1
    assert_not @quran.valid?
    assert_includes @quran.errors[:stock], "must be greater than or equal to 0"
  end

  test "stock should be zero or positive" do
    @quran.stock = 0
    assert @quran.valid?
    assert @quran.stock >= 0
  end

  # Association Tests
  test "should have many attached images" do
    skip "Images require ActiveStorage which is not available in test environment"
  end

  # Business Logic Tests
  test "should have correct translation options" do
    valid_translations = ['english', 'urdu', 'french', 'spanish', 'arabic']
    valid_translations.each do |translation|
      @quran.translation = translation
      assert @quran.valid?, "#{translation} should be valid"
    end
  end

  test "should return capitalized translation" do
    @quran.translation = "english"
    assert_equal "English", @quran.translation.capitalize
  end

  # Creation and Persistence Tests
  test "should save successfully with valid data" do
    assert_difference('Quran.count', 1) do
      @quran.save!
    end

    saved_quran = Quran.last
    assert_equal @quran.title, saved_quran.title
    assert_equal @quran.writer, saved_quran.writer
    assert_equal @quran.translation, saved_quran.translation
    assert_equal @quran.pages, saved_quran.pages
    assert_equal @quran.stock, saved_quran.stock
  end

  test "should update successfully" do
    @quran.save!
    original_title = @quran.title

    @quran.update!(title: "Updated Quran Title")
    @quran.reload

    assert_not_equal original_title, @quran.title
    assert_equal "Updated Quran Title", @quran.title
  end

  test "should filter available qurans by stock" do
    quran_in_stock = Quran.create!(
      title: "In Stock Quran",
      writer: "Test Author",
      translation: "english",
      pages: 500,
      stock: 10
    )

    quran_out_of_stock = Quran.create!(
      title: "Out of Stock Quran",
      writer: "Test Author",
      translation: "english",
      pages: 500,
      stock: 0
    )

    available_qurans = Quran.where('stock > 0')
    assert_includes available_qurans, quran_in_stock
    refute_includes available_qurans, quran_out_of_stock
  end

  # Data Integrity Tests
  test "should maintain data integrity for large pages count" do
    @quran.pages = 5000
    assert @quran.valid?
    @quran.save!
    assert_equal 5000, @quran.reload.pages
  end

  test "should handle large stock quantities" do
    @quran.stock = 10000
    assert @quran.valid?
    @quran.save!
    assert_equal 10000, @quran.reload.stock
  end

  # Edge Cases
  test "should handle nil description gracefully" do
    @quran.description = nil
    assert @quran.valid?
    @quran.save!
    assert_nil @quran.reload.description
  end

  test "should handle very long descriptions" do
    long_description = "A" * 1000
    @quran.description = long_description
    assert @quran.valid?
    @quran.save!
    assert_equal long_description, @quran.reload.description
  end
end
