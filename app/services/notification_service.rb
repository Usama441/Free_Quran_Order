# app/services/notification_service.rb
class NotificationService
    def self.send_daily_summary
      orders_count = Order.where(created_at: Date.yesterday.all_day).count
      NotificationActivity.log_daily_summary(orders_count)
      
      # Here you would also send actual emails
      # AdminMailer.daily_summary(orders_count).deliver_later
    end

    def self.send_new_order(order)
      NotificationActivity.log_new_order(order)
      
      # Here you would also send actual emails
      # AdminMailer.new_order(order).deliver_later
    end
  
    def self.send_low_stock_alert(quran_type, current_stock, threshold)
      NotificationActivity.log_low_stock_alert(quran_type, current_stock, threshold)
      
      # Here you would also send actual alerts
      # AdminMailer.low_stock_alert(quran_type, current_stock, threshold).deliver_later
    end
  
    def self.send_slack_notification(message)
      # Your Slack integration code here
      # Then log the activity
      NotificationActivity.log_slack_notification(message)
    end
  
    def self.send_webhook_notification(event_type, payload)
      # Your webhook integration code here
      # Then log the activity
      webhook_url = # get from your settings
      NotificationActivity.log_webhook_notification(event_type, payload, webhook_url)
    end
  end