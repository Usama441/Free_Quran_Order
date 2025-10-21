class Admin < ApplicationRecord
  # Add Devise modules you need
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  enum role: { manager: 0, super_admin: 1 }

  validates :role, presence: true
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }

  after_initialize do
    self.role ||= :manager
  end

  # Helper method to get full name
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Role-based permission methods
  def super_admin?
    role == "super_admin"
  end

  def manager?
    role == "manager"
  end

  def can_manage_admins?
    super_admin?
  end

  def can_manage_orders?
    super_admin? || manager?
  end

  def can_manage_qurans?
    super_admin? || manager?
  end

  def can_manage_settings?
    super_admin?
  end

  def can_view_analytics?
    super_admin? || manager?
  end
end
