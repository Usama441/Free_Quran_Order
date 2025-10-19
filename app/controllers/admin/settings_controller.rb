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
      # Use safe YAML loading with permitted classes
      safe_yaml_load(settings_path)
    else
      {
        'email_on_new_order' => true,
        'email_daily_summary' => false,
        'email_weekly_report' => false,
        'sms_alerts_low_stock' => true,
        'slack_notifications' => false,
        'webhook_url' => '',
        'notification_emails' => ''
      }
    end
  end

  def safe_yaml_load(file_path)
    # Read the file content
    content = File.read(file_path)
    
    # Remove the problematic Ruby-specific YAML tags
    cleaned_content = content.gsub(/!ruby\/[^\s]+/, '')
    
    # Load the cleaned YAML
    YAML.safe_load(cleaned_content, permitted_classes: [Symbol]) || {}
  end

  def update_notification_settings(settings)
    new_settings = settings.to_h.transform_values do |value|
      case value
      when 'true', '1', 'on' then true
      when 'false', '0', nil, '' then false
      else value
      end
    end
  
    # Convert to regular Hash to avoid ActiveSupport::HashWithIndifferentAccess
    settings_to_save = new_settings.stringify_keys
  
    settings_path = Rails.root.join('config', 'notification_settings.yml')
    
    # Write clean YAML without Ruby-specific tags
    File.open(settings_path, 'w') do |f|
      f.write(settings_to_save.to_yaml)
    end
  
    true
  end

  def notification_params
    params.require(:notification).permit(
      :email_on_new_order, :email_daily_summary, :email_weekly_report,
      :sms_alerts_low_stock, :slack_notifications,
      :webhook_url, :notification_emails
    )
  end

  def update_settings(settings)
    # Convert to hash with string keys for YAML
    new_settings = settings.to_h
    
    # Convert form values to proper types
    new_settings = convert_form_values(new_settings)
    
    # Merge with existing settings to preserve any missing keys
    updated_settings = app_settings.merge(new_settings)
    
    # Save to YAML
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