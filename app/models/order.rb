class Order < ApplicationRecord
  enum status: { pending: 0, processing: 1, shipped: 2, delivered: 3, cancelled: 4 }

  # Association with Quran (orders belong to qurans)
  belongs_to :quran, polymorphic: true, optional: true

  # Real-time broadcasting for live updates
  after_update :broadcast_order_update, if: :saved_change_to_status?
  before_save :reduce_quran_stock, if: -> { quran.present? && new_record? }
  before_validation :check_stock_availability, if: -> { quran.present? }

  private

  def broadcast_order_update
    # Broadcast to all connected admin clients
    OrderBroadcastJob.perform_later(id)
  end

  def check_stock_availability
    return if quantity.blank? || quran.blank?

    if quantity > quran.stock
      errors.add(:quantity, "Only #{quran.stock} Qurans available in stock. Cannot order #{quantity}.")
    end
  end

  def reduce_quran_stock
    return if quantity.blank? || quran.blank?

    quran.with_lock do
      if quran.stock >= quantity
        quran.update!(stock: quran.stock - quantity)
        Rails.logger.info "Stock reduced for Quran ##{quran.id} (#{quran.title}): -#{quantity}, remaining: #{quran.stock}"

        # Notification triggers are handled in Quran model after_save callback
      else
        raise ActiveRecord::Rollback, "Insufficient stock: Only #{quran.stock} available, ordered #{quantity}"
      end
    end
  end

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
