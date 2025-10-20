# app/helpers/settings_helper.rb
module SettingsHelper
    def app_settings
      @app_settings ||= load_app_settings
    end

    def site_name
        app_settings['site_name'] || 'Free Quran Distribution'
    end

    def order_limit_per_day
        app_settings['order_limit_per_day'] || 50
    end
    
    def max_daily_orders
      app_settings['max_daily_orders'] || 100
    end

    def default_translation
      app_settings['default_translation'] || 'english'
    end

    def auto_refresh_interval
      app_settings['auto_refresh_interval'] || 30
    end

    def debug_mode?
      app_settings['debug_mode'] || false
    end
  
    def maintenance_mode?
      app_settings['maintenance_mode'] || false
    end
  
    def notification_settings
      @notification_settings ||= load_notification_settings
    end
  
    def email_on_new_order?
      notification_settings['email_on_new_order'] || true
    end

    def email_daily_summary?
      notification_settings['email_daily_summary'] || false
    end

    def email_weekly_report?
      notification_settings['email_weekly_report'] || false
    end

    def sms_alerts_low_stock?
      notification_settings['sms_alerts_low_stock'] || true
    end

    def webhook_url
      notification_settings['webhook_url'] || ''
    end

    def notification_emails
      notification_settings['notification_emails'] || ''
    end
  
    def slack_notifications?
      notification_settings['slack_notifications'] || false
    end
  
    def update_app_settings(new_settings)
      settings_file = Rails.root.join('config', 'app_settings.yml')
      File.write(settings_file, new_settings.to_yaml)
      @app_settings = nil # Clear cache to reload settings
    end
  
    private
  
    def load_app_settings
      settings_file = Rails.root.join('config', 'app_settings.yml')
      
      if File.exist?(settings_file)
        YAML.load_file(settings_file)
      else
        # Default settings if file doesn't exist
        default_settings = {
          'site_name' => 'Free Quran Distribution',
          'default_translation' => 'english',
          'order_limit_per_day' => 50,
          'email_notifications' => true,
          'auto_refresh_interval' => 30,
          'max_daily_orders' => 100,
          'debug_mode' => false,
          'maintenance_mode' => false,
          'low_stock_threshold' => 100,
          'auto_reorder_point' => 50
        }
        File.write(settings_file, default_settings.to_yaml)
        default_settings
      end
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
            'notification_emails' => ''
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
  end