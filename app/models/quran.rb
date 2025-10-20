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

  after_save :check_low_stock, if: :saved_change_to_stock?


  private

  def check_low_stock
    notification_settings = load_notification_settings
    threshold = load_low_stock_threshold

    if stock.present? && stock < threshold && notification_settings['sms_alerts_low_stock']
      WebhookNotificationService.send_low_stock_notification(self)
    end 
  end

  def load_low_stock_threshold
    settings_path = Rails.root.join('config', 'app_settings.yml')
    if File.exist?(settings_path)
      settings = YAML.safe_load(File.read(settings_path)) || {}
      (settings['low_stock_threshold'] || 5).to_i
    else
      5
    end
  rescue => e
    Rails.logger.error "Failed to read low stock threshold: #{e.message}"
    5
  end

  def images_count
    # Skip validation in test environment if ActiveStorage not available
    return unless defined?(ActiveStorage) && images.attached?

    if images.length > 5
      errors.add(:images, 'cannot have more than 5 images')
    end
  end

  def load_notification_settings
    settings_path = Rails.root.join('config', 'notification_settings.yml')
    if File.exist?(settings_path)
      YAML.safe_load(File.read(settings_path)) || {}
    else
      {}
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
