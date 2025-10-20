# app/jobs/daily_summary_job.rb
class DailySummaryJob < ApplicationJob
    queue_as :default
  
    def perform
      # Calculate orders from yesterday
      orders = Order.where(created_at: Date.yesterday.all_day)

      WebhookNotificationService.send_daily_summary_notification(orders)
      
      Rails.logger.info "📊 Daily summary sent: #{orders.length} orders from #{Date.yesterday}"
    end
    
  end