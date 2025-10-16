class Admin::SettingsController < ApplicationController
  before_action :authenticate_admin!

  def configuration
    # Configuration settings
    @app_settings = {
      site_name: "Free Quran Distribution",
      default_translation: "english",
      order_limit_per_day: 50,
      email_notifications: true,
      auto_refresh_interval: 30, # seconds
      max_daily_orders: 100
    }

    if request.patch?
      # Handle settings update
      # In a real app, you'd save these to database
      flash[:notice] = "Configuration updated successfully!"
      redirect_to admin_configuration_path
    end
  end

  def notifications
    # Notification settings
    @notification_settings = {
      email_on_new_order: true,
      email_daily_summary: true,
      email_weekly_report: false,
      slack_notifications: false,
      sms_alerts_low_stock: true,
      webhook_url: "",
      notification_emails: ""
    }

    if request.patch?
      # Handle notification settings update
      flash[:notice] = "Notification settings updated successfully!"
      redirect_to admin_notifications_path
    end
  end
end
