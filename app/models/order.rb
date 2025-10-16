class Order < ApplicationRecord
  enum status: { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4 }

  # Association with Quran (orders belong to qurans)
  belongs_to :quran, optional: true

  validates :full_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :postal_code, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :country_code, presence: true

  # Default values
  attribute :quantity, :integer, default: 1
  attribute :translation, :string, default: 'english'
  attribute :country_code, :string, default: '+92'
end
