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

  after_save :check_stock_alerts, if: :saved_change_to_stock?

  # Instance methods
  def stock_status
    return :out_of_stock if stock <= 0
    return :critical if stock < 5
    return :low if stock < load_low_stock_threshold
    return :warning if stock < 25
    :normal
  end

  def stock_status_color
    case stock_status
    when :out_of_stock then 'red'
    when :critical then 'red'
    when :low then 'orange'
    when :warning then 'yellow'
    else 'green'
    end
  end

  def stock_alert_message
    case stock_status
    when :out_of_stock then "🚨 OUT OF STOCK - Immediate restocking required!"
    when :critical then "🚨 CRITICAL: Only #{stock} copies remaining!"
    when :low then "⚠️ Low stock: #{stock} copies (below threshold of #{load_low_stock_threshold})"
    when :warning then "ℹ️ Stock warning: #{stock} copies remaining"
    else nil
    end
  end

  private

  def check_stock_alerts
    case stock_status
    when :out_of_stock, :critical
      send_immediate_stock_alert
    when :low
      send_low_stock_alert
    when :warning
      log_stock_warning
    end
  end

  def send_immediate_stock_alert
    notification_settings = load_notification_settings
    if notification_settings['enable_discord_notifications'] && notification_settings['discord_webhook_url'].present?
      WebhookNotificationService.send_immediate_stock_alert(self)
    end
    Rails.logger.warn "IMMEDIATE STOCK ALERT: #{title} has #{stock} copies remaining"
  end

  def send_low_stock_alert
    notification_settings = load_notification_settings
    if notification_settings['sms_alerts_low_stock'] || notification_settings['enable_discord_notifications']
      WebhookNotificationService.send_low_stock_notification(self)
    end
    Rails.logger.info "LOW STOCK ALERT: #{title} has #{stock} copies remaining (below threshold)"
  end

  def log_stock_warning
    Rails.logger.info "STOCK WARNING: #{title} has #{stock} copies remaining"
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
