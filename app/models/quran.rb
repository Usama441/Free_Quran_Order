class Quran < ApplicationRecord
  has_many :orders
  # Validations
  validates :title, presence: true, uniqueness: true
  validates :writer, presence: true
  validates :translation, presence: true
  validates :pages, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Image attachment - requires ActiveStorage (conditionally loaded)
  if defined?(ActiveStorage)
    has_many_attached :images, dependent: :destroy

    # Image validation
    validate :images_count
    validate :images_type
  end

  private

  def images_count
    # Skip validation in test environment if ActiveStorage not available
    return unless defined?(ActiveStorage) && images.attached?

    if images.length > 5
      errors.add(:images, 'cannot have more than 5 images')
    end
  end

  def images_type
    # Skip validation in test environment if ActiveStorage not available
    return unless defined?(ActiveStorage) && images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
        errors.add(:images, 'must be JPG, PNG, GIF, or WebP')
      end
    end
  end
end
