class Admin < ApplicationRecord
  # Add Devise modules you need
  devise :database_authenticatable, :recoverable, :rememberable, :validatable
end