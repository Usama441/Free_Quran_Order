require 'ostruct'

# app/controllers/admin/settings_controller.rb
class Admin::SettingsController < ApplicationController
  include SettingsHelper
  before_action :authenticate_admin!

  def configuration
    @app_settings = app_settings
    @system_status = check_system_status

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

  def check_system_status
    database_status = check_database_connection
    background_jobs_status = check_background_jobs
    file_storage_status = check_file_storage
    redis_status = check_redis_connection

    {
      database: database_status,
      background_jobs: background_jobs_status,
      file_storage: file_storage_status,
      redis: redis_status,
      last_check: Time.current,
      uptime: calculate_uptime,
      system_health: calculate_system_health(database_status, background_jobs_status, file_storage_status)
    }
  end

  def check_database_connection
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      { status: 'connected', healthy: true, message: 'Connected' }
    rescue => e
      Rails.logger.error "Database connection check failed: #{e.message}"
      { status: 'disconnected', healthy: false, message: e.message }
    end
  end

  def check_background_jobs
    begin
      if defined?(Sidekiq)
        stats = Sidekiq::Stats.new
        {
          status: 'active',
          healthy: stats.processes_size > 0,
          message: "#{stats.processes_size} processes running",
          details: {
            processed: stats.processed,
            failed: stats.failed,
            enqueued: stats.enqueued
          }
        }
      else
        { status: 'active', healthy: true, message: 'ActiveJob running' }
      end
    rescue => e
      Rails.logger.error "Background jobs check failed: #{e.message}"
      { status: 'inactive', healthy: false, message: e.message }
    end
  end


  def check_file_storage
    begin
      if Rails.application.config.active_storage.service == :local
        storage_path = Rails.root.join('storage')
        if File.writable?(storage_path)
          { status: 'ok', healthy: true, message: 'Writable' }
        else
          { status: 'readonly', healthy: false, message: 'Storage directory not writable' }
        end
      else
        { status: 'ok', healthy: true, message: 'Cloud storage configured' }
      end
    rescue => e
      Rails.logger.error "File storage check failed: #{e.message}"
      { status: 'error', healthy: false, message: e.message }
    end
  end

  def check_redis_connection
    begin
      if defined?(Redis)
        redis = Redis.new
        redis.ping
        { status: 'connected', healthy: true, message: 'Connected' }
      else
        { status: 'not_configured', healthy: true, message: 'Not in use' }
      end
    rescue => e
      Rails.logger.error "Redis connection check failed: #{e.message}"
      { status: 'disconnected', healthy: false, message: e.message }
    end
  end

  def calculate_uptime
    begin
      if File.exist?('/proc/uptime')
        uptime_seconds = File.read('/proc/uptime').split[0].to_i
        format_duration(uptime_seconds)
      else
        # Fallback to application start time (approximate)
        @app_start_time ||= Time.current - 1.hour # Default to 1 hour ago
        format_duration(Time.current - @app_start_time)
      end
    rescue => e
      Rails.logger.error "Uptime calculation failed: #{e.message}"
      "Unknown"
    end
  end
  
  def format_duration(seconds)
    seconds = seconds.to_i
    days = seconds / (24 * 3600)
    seconds %= (24 * 3600)
    hours = seconds / 3600
    seconds %= 3600
    minutes = seconds / 60
    seconds %= 60

    parts = []
    parts << "#{days} day#{'s' unless days == 1}" if days > 0
    parts << "#{hours} hour#{'s' unless hours == 1}" if hours > 0
    parts << "#{minutes} minute#{'s' unless minutes == 1}" if minutes > 0
    parts << "#{seconds} second#{'s' unless seconds == 1}" if seconds > 0 && parts.empty?

    parts.empty? ? "Less than 1 second" : parts.join(', ')
  end

  def calculate_system_health(database_status, background_jobs_status, file_storage_status)
    # Ensure all status objects are present and have the expected structure
    statuses = [
      database_status || { healthy: false },
      background_jobs_status || { healthy: false },
      file_storage_status || { healthy: false }
    ]

    # Count healthy statuses, treating nil/missing healthy as false
    healthy_count = statuses.count do |status|
      status.is_a?(Hash) && status[:healthy] == true
    end

    total_count = statuses.size

    case (healthy_count.to_f / total_count * 100)
    when 90..100
      'excellent'
    when 75...90
      'good'
    when 50...75
      'fair'
    else
      'poor'
    end
  rescue => e
    Rails.logger.error "System health calculation failed: #{e.message}"
    'unknown'
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