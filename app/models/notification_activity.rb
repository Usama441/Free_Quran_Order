class NotificationActivity < ApplicationRecord
    # Event types
    EVENT_TYPES = {
      new_order: 'new_order',
      daily_summary: 'daily_summary',
      weekly_report: 'weekly_report',
      low_stock: 'low_stock',
      system_alert: 'system_alert',
      slack_notification: 'slack_notification',
      webhook_notification: 'webhook_notification'
    }.freeze
  
    # Statuses
    STATUSES = {
      sent: 'sent',
      failed: 'failed',
      pending: 'pending'
    }.freeze
  
    validates :event_type, presence: true
    validates :title, presence: true
    validates :message, presence: true
  
    # Scopes for easy querying
    scope :recent, -> { order(created_at: :desc).limit(50) }
    scope :by_event_type, ->(event_type) { where(event_type: event_type) }
    scope :successful, -> { where(status: 'sent') }
    scope :failed, -> { where(status: 'failed') }
  
    # Class methods to create different types of notifications
    def self.log_new_order(order)
      create(
        event_type: EVENT_TYPES[:new_order],
        title: "New Order Notification",
        message: "Order ##{order.id} from #{order.country_code}",
        metadata: {
          order_id: order.id,
          customer_email: order.email,
          country: order.country_code,
          translation: order.translation
        },
        sent_to: 'email', # or 'slack', 'webhook', etc.
        status: STATUSES[:sent]
      )
    end
  
    def self.log_daily_summary(orders_count, date = Date.yesterday)
      create(
        event_type: EVENT_TYPES[:daily_summary],
        title: "Daily Summary Email",
        message: "#{orders_count} orders processed on #{date.strftime('%Y-%m-%d')}",
        metadata: {
          orders_count: orders_count,
          date: date,
          report_type: 'daily'
        },
        sent_to: 'email',
        status: STATUSES[:sent]
      )
    end
  
    def self.log_low_stock_alert(quran_type, current_stock, threshold)
      create(
        event_type: EVENT_TYPES[:low_stock],
        title: "Low Stock Alert",
        message: "#{quran_type} Quran stock below #{threshold} units (current: #{current_stock})",
        metadata: {
          quran_type: quran_type,
          current_stock: current_stock,
          threshold: threshold
        },
        sent_to: 'email',
        status: STATUSES[:sent]
      )
    end
  
    def self.log_slack_notification(message, channel = '#orders')
      create(
        event_type: EVENT_TYPES[:slack_notification],
        title: "Slack Notification",
        message: message,
        metadata: {
          channel: channel,
          message: message
        },
        sent_to: 'slack',
        status: STATUSES[:sent]
      )
    end
  
    def self.log_webhook_notification(event_type, payload, url)
      create(
        event_type: EVENT_TYPES[:webhook_notification],
        title: "Webhook Notification",
        message: "Sent #{event_type} to #{url}",
        metadata: {
          event_type: event_type,
          payload: payload,
          url: url
        },
        sent_to: 'webhook',
        status: STATUSES[:sent]
      )
    end
  
    def self.log_failed_notification(event_type, error_message, recipient)
      create(
        event_type: event_type,
        title: "Failed Notification",
        message: "Failed to send #{event_type} to #{recipient}: #{error_message}",
        metadata: {
          error: error_message,
          recipient: recipient
        },
        sent_to: recipient,
        status: STATUSES[:failed]
      )
    end
  
    # Helper method to display time ago
    def time_ago
      ActionController::Base.helpers.time_ago_in_words(created_at) + ' ago'
    end
  
    # Helper method to get appropriate icon based on event type
    def icon_class
      case event_type
      when EVENT_TYPES[:new_order]
        'fas fa-envelope'
      when EVENT_TYPES[:daily_summary], EVENT_TYPES[:weekly_report]
        'fas fa-chart-line'
      when EVENT_TYPES[:low_stock]
        'fas fa-exclamation-triangle'
      when EVENT_TYPES[:slack_notification]
        'fab fa-slack'
      when EVENT_TYPES[:webhook_notification]
        'fas fa-plug'
      else
        'fas fa-bell'
      end
    end
  
    # Helper method to get appropriate color based on event type and status
    def color_class
      if status == 'failed'
        'bg-red-50 border-l-4 border-red-500 text-red-700'
      else
        case event_type
        when EVENT_TYPES[:new_order]
          'bg-green-50 border-l-4 border-green-500 text-green-700'
        when EVENT_TYPES[:daily_summary], EVENT_TYPES[:weekly_report]
          'bg-blue-50 border-l-4 border-blue-500 text-blue-700'
        when EVENT_TYPES[:low_stock]
          'bg-orange-50 border-l-4 border-orange-500 text-orange-700'
        when EVENT_TYPES[:slack_notification]
          'bg-purple-50 border-l-4 border-purple-500 text-purple-700'
        when EVENT_TYPES[:webhook_notification]
          'bg-indigo-50 border-l-4 border-indigo-500 text-indigo-700'
        else
          'bg-gray-50 border-l-4 border-gray-500 text-gray-700'
        end
      end
    end
  end