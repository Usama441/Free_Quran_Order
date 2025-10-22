# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create sample Qurans
puts "Creating sample Qurans..."

qurans = [
  {
    title: "The Holy Quran - English Translation",
    writer: "Dr. Muhammad Muhsin Khan",
    translation: "english",
    pages: 604,
    stock: 1500,
    description: "Complete English translation of the Holy Quran with clear and easy to read text."
  },
  {
    title: "Al-Quran Al-Kareem - Urdu Translation",
    writer: "Maulana Fateh Muhammad Jalandhari",
    translation: "urdu",
    pages: 620,
    stock: 1200,
    description: "Beautiful Urdu translation by renowned Islamic scholar Jalandhari Sahib."
  },
  {
    title: "Quran with French Translation",
    writer: "Muhammad Hamidullah",
    translation: "french",
    pages: 590,
    stock: 800,
    description: "Comprehensive French translation of the Holy Quran."
  },
  {
    title: "Quran with Spanish Translation",
    writer: "Julio Cortés",
    translation: "spanish",
    pages: 605,
    stock: 950,
    description: "Spanish translation of the Holy Quran for Hispanic communities."
  }
]

created_qurans = []
qurans.each do |quran_data|
  quran = Quran.find_or_create_by(title: quran_data[:title]) do |q|
    q.writer = quran_data[:writer]
    q.translation = quran_data[:translation]
    q.pages = quran_data[:pages]
    q.stock = quran_data[:stock]
    q.description = quran_data[:description]
  end
  created_qurans << quran
end

puts "Created #{created_qurans.size} Qurans"

# Create sample admin user
puts "Creating admin user..."

Admin.find_or_create_by(email: "admin@example.com") do |admin|
  admin.first_name = "Super"
  admin.last_name = "Admin"
  admin.password = "password123"
  admin.password_confirmation = "password123"
  admin.role = :super_admin  # Make the default admin a super admin
  admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
end

puts "Admin user created with email: admin@example.com, password: password123 (Super Admin)"

# Create sample orders to demonstrate dashboard functionality
puts "Creating sample orders..."

# Country codes to use for diverse heatmap
country_codes = ['PK', 'US', 'GB', 'AE', 'SA', 'FR', 'DE', 'CA', 'AU', 'IN']

# Generate orders over the past few months
(1..6).each do |month_ago|
  date = month_ago.months.ago
  orders_count = rand(15..50) # Random orders per month

  orders_count.times do
    order_date = date + rand(30).days
    country_code = country_codes.sample

    Order.find_or_create_by(
      full_name: Faker::Name.name,
      email: Faker::Internet.email,
      phone: Faker::PhoneNumber.cell_phone_with_country_code,
      created_at: order_date
    ) do |order|
      order.country_code = country_code
      order.city = Faker::Address.city
      order.state = Faker::Address.state
      order.postal_code = Faker::Address.postcode
      order.address = Faker::Address.street_address
      order.quantity = rand(1..5)
      order.note = [nil, "Special translation request", "Urgent delivery", "Large print edition"].sample
    end
  end
end

puts "Seeded database with sample data!"

# Create a few orders with specific countries to ensure heatmap visibility
puts "Creating additional orders for specific countries..."

# Ensure Pakistan has many orders (will show as large red dot)
25.times do |i|
  Order.find_or_create_by(
    full_name: "Pakistani Customer #{i+1}",
    email: "pakistani#{i+1}@example.com",
      created_at: (rand(6).months).ago
  ) do |order|
    order.country_code = 'PK'
    order.city = "Lahore"
    order.state = "Punjab"
    order.phone = "+92 300 1234567"
    order.quantity = rand(1..3)
    order.address = "House #{rand(1000)}, Street #{rand(50)}, Model Town"
    order.postal_code = "54000"
  end
end

# Ensure USA has good representation too
15.times do |i|
  Order.find_or_create_by(
    full_name: "American Customer #{i+1}",
    email: "american#{i+1}@example.com",
    created_at: (rand(4).months).ago
  ) do |order|
    order.country_code = 'US'
    order.city = "New York"
    order.state = "NY"
    order.phone = "+1 555-1234"
    order.quantity = rand(1..2)
    order.address = "#{rand(1000)} Main St"
    order.postal_code = "10001"
  end
end

# Display summary
puts "\n=== Dashboard Test Data Summary ==="
puts "Total Orders: #{Order.count}"
puts "Countries Served: #{Order.distinct.pluck(:country_code).count}"
countries_with_counts = Order.group(:country_code).count
puts "Orders by Country:"
countries_with_counts.each do |country, count|
  puts "  #{country}: #{count} orders"
end
puts "Qurans Distributed: #{Order.sum(:quantity)}"
puts "Stock Remaining: #{Quran.sum(:stock)}"
puts "\nAdmin Login: admin@example.com / password123"
puts "Dashboard URL: http://localhost:3001/admin/dashboard"
