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


  def debug_mode?
    app_settings['debug_mode'] || false
  end

  def maintenance_mode?
    app_settings['maintenance_mode'] || false
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
  end