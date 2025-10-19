require 'ostruct'

# app/controllers/admin/settings_controller.rb
class Admin::SettingsController < ApplicationController
  include SettingsHelper
  before_action :authenticate_admin!

  def configuration
    @app_settings = app_settings

    if request.patch?
      if update_settings(settings_params)
        flash[:notice] = "Configuration updated successfully!"
        redirect_to admin_configuration_path
      else
        flash[:alert] = "Failed to update configuration!"
        render :configuration
      end
    end
  end

  def notifications
    @notification_settings = load_notification_settings
    @recent_activities = NotificationActivity.recent.limit(10)

    if request.patch?
      if update_notification_settings(notification_params)
        flash[:notice] = "Notification settings updated successfully!"
        redirect_to admin_notifications_path
      else
        flash[:alert] = "Failed to update notification settings!"
        render :notifications
      end
    end
  end

  def clear_notification_history
    NotificationActivity.destroy_all
    redirect_to admin_notifications_path, notice: "Notification history cleared successfully!"
  end

  private

  def settings_params
    params.require(:app).permit(
      :site_name, :default_translation, :order_limit_per_day, 
      :email_notifications, :auto_refresh_interval, :max_daily_orders,
      :debug_mode, :maintenance_mode, :low_stock_threshold, :auto_reorder_point
    )
  end

  def load_notification_settings
    settings_path = Rails.root.join('config', 'notification_settings.yml')
    if File.exist?(settings_path)
      safe_yaml_load(settings_path)
    else
      {
        'email_on_new_order' => true,
        'email_daily_summary' => false,
        'email_weekly_report' => false,
        'sms_alerts_low_stock' => true,
        'slack_notifications' => false,
        'webhook_url' => '',
        'notification_emails' => '',
        'discord_webhook_url' => '',
        'whatsapp_webhook_url' => '',
        'enable_discord_notifications' => false,
        'enable_whatsapp_notifications' => false
      }
    end
  end

  def safe_yaml_load(file_path)
    content = File.read(file_path)
    cleaned_content = content.gsub(/!ruby\/[^\s]+/, '')
    YAML.safe_load(cleaned_content, permitted_classes: [Symbol]) || {}
  rescue => e
    Rails.logger.error "Failed to load notification settings: #{e.message}"
    {}
  end

  def update_notification_settings(settings)
    new_settings = settings.to_h.transform_values do |value|
      case value
      when 'true', '1', 'on' then true
      when 'false', '0', nil, '' then false
      else value
      end
    end

    # Debug: Log the received parameters
    Rails.logger.info "Received notification settings: #{new_settings.inspect}"

    settings_to_save = new_settings.stringify_keys
    settings_path = Rails.root.join('config', 'notification_settings.yml')
    
    # Ensure all expected keys are present
    default_settings = {
      'email_on_new_order' => false,
      'email_daily_summary' => false,
      'email_weekly_report' => false,
      'sms_alerts_low_stock' => false,
      'slack_notifications' => false,
      'webhook_url' => '',
      'notification_emails' => '',
      'discord_webhook_url' => '',
      'whatsapp_webhook_url' => '',
      'enable_discord_notifications' => false,
      'enable_whatsapp_notifications' => false
    }

    # Merge with defaults to ensure all keys exist
    final_settings = default_settings.merge(settings_to_save)
    
    File.open(settings_path, 'w') do |f|
      f.write(final_settings.to_yaml)
    end

    # Debug: Log what was saved
    Rails.logger.info "Saved notification settings: #{final_settings.inspect}"

    true
  end


  def notification_params
    params.require(:notification).permit(
      :email_on_new_order, :email_daily_summary, :email_weekly_report,
      :sms_alerts_low_stock, :slack_notifications,
      :webhook_url, :notification_emails,
      :discord_webhook_url, :whatsapp_webhook_url,
      :enable_discord_notifications, :enable_whatsapp_notifications
    )
  end

  def update_settings(settings)
    new_settings = settings.to_h
    new_settings = convert_form_values(new_settings)
    updated_settings = app_settings.merge(new_settings)
    update_app_settings(updated_settings)
    true
  end

  def convert_form_values(settings)
    settings.transform_values do |value|
      case value
      when 'true', '1', 1
        true
      when 'false', '0', 0, nil, ''
        false
      when /^\d+$/
        value.to_i
      else
        value
      end
    end
  end
end