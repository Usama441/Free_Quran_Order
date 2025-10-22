# spec/factories.rb
FactoryBot.define do
  factory :admin do
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name) { |n| "Last#{n}" }
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :manager }

    trait :manager do
      role { :manager }
    end

    trait :super_admin do
      role { :super_admin }
    end

    trait :confirmed do
      confirmed_at { Time.now }
    end

    trait :locked do
      locked_at { Time.now }
    end

    factory :manager_admin, traits: [:manager, :confirmed]
    factory :super_admin_admin, traits: [:super_admin, :confirmed]
  end

  factory :order do
    sequence(:full_name) { |n| "Customer #{n}" }
    sequence(:email) { |n| "customer#{n}@example.com" }
    phone { "+123456789#{rand(1000..9999)}" }
    quantity { 1 }
    status { :pending }
    country_code { ['US', 'PK', 'GB', 'FR', 'DE', 'CA', 'AU'].sample }
    sequence(:city) { |n| "City#{n}" }
    state { "State" }
    postal_code { "12345" }
    address { "123 Main St" }
    note { nil }

    trait :pending do
      status { :pending }
    end

    trait :processing do
      status { :processing }
    end

    trait :shipped do
      status { :shipped }
    end

    trait :delivered do
      status { :delivered }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_quran do
      association :quran
    end

    factory :pending_order, traits: [:pending]
    factory :processing_order, traits: [:processing]
    factory :shipped_order, traits: [:shipped]
    factory :delivered_order, traits: [:delivered]
    factory :cancelled_order, traits: [:cancelled]
  end

  factory :quran do
    sequence(:title) { |n| "Quran Book #{n}" }
    writer { "Author #{rand(100..999)}" }
    translation { ['english', 'urdu', 'french', 'spanish', 'arabic'].sample }
    pages { rand(300..700) }
    stock { rand(50..1000) }
    description { Faker::Lorem.paragraph(sentence_count: 3) }

    trait :english do
      translation { 'english' }
    end

    trait :urdu do
      translation { 'urdu' }
    end

    trait :out_of_stock do
      stock { 0 }
    end

    trait :low_stock do
      stock { rand(1..10) }
    end

    factory :english_quran, traits: [:english]
    factory :urdu_quran, traits: [:urdu]
  end

  factory :notification_activity do
    admin { nil }
    action { ['created', 'updated', 'deleted'].sample }
    resource_type { ['Order', 'Quran', 'Admin'].sample }
    resource_id { rand(1..1000) }
    description { Faker::Lorem.sentence(word_count: 8) }
    metadata { { additional_info: Faker::Lorem.words(number: 3).join(' ') } }

    trait :by_admin do
      association :admin
    end
  end

  factory :export_history do
    admin { nil }
    format { ['pdf', 'csv', 'excel'].sample }
    resource_type { ['Order', 'Quran', 'Customer'].sample }
    record_count { rand(10..1000) }
    file_path { "/tmp/export_#{SecureRandom.hex(8)}.#{['pdf', 'csv', 'xlsx'].sample}" }
    filters { { start_date: 1.month.ago.to_date, end_date: Date.current } }


    trait :successful do
      status { 'completed' }
    end

    trait :failed do
      status { 'failed' }
      error_message { "Export failed: #{Faker::Lorem.sentence}" }
    end

    factory :successful_export, traits: [:successful]
    factory :failed_export, traits: [:failed]
  end
end
