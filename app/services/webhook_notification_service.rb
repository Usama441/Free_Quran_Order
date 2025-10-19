# app/services/webhook_notification_service.rb
class WebhookNotificationService

    def self.send_test_notification
        settings = load_notification_settings
        
        puts "=== WEBHOOK DEBUG INFO ===".yellow
        puts "Discord enabled: #{settings['enable_discord_notifications']}"
        puts "Discord URL present: #{settings['discord_webhook_url'].present?}"
        puts "Discord URL: #{settings['discord_webhook_url']}"
        puts "==========================".yellow
    
        message = "🧪 **Test Notification**\n" +
                  "This is a test message from your Quran Distribution app.\n" +
                  "**Time:** #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n" +
                  "**App:** Quran Distribution System\n" +
                  "**Status:** ✅ Webhook is working correctly!"
    
        success_count = 0
        total_attempts = 0
        results = []
    
        # Send to Discord if enabled
        if settings['enable_discord_notifications'] && settings['discord_webhook_url'].present?
          total_attempts += 1
          discord_result = send_discord_notification(message, settings['discord_webhook_url'])
          success_count += 1 if discord_result
          results << { service: 'discord', success: discord_result }
        end
    
        # Send to generic webhook if enabled
        if settings['webhook_url'].present?
          total_attempts += 1
          webhook_result = send_generic_webhook(message, settings['webhook_url'])
          success_count += 1 if webhook_result
          results << { service: 'generic', success: webhook_result }
        end
    
        {
          success_count: success_count,
          total_attempts: total_attempts,
          results: results,
          message: "Sent #{success_count}/#{total_attempts} test notifications"
        }
    end

    def self.send_low_stock_notification(quran)
        settings = load_notification_settings
        
        return unless settings['enable_discord_notifications'] && settings['discord_webhook_url'].present?
      
        require 'net/http'
        require 'uri'
        
        begin
          uri = URI.parse(settings['discord_webhook_url'])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          payload = {
            content: "⚠️ **LOW STOCK ALERT!**",
            username: 'Quran Distribution Bot',
            avatar_url: 'https://cdn-icons-png.flaticon.com/512/210/210626.png',
            embeds: [
              {
                title: "Stock Alert",
                color: 15105570, # Orange color
                fields: [
                  {
                    name: "📖 Quran",
                    value: quran.title,
                    inline: true
                  },
                  {
                    name: "📊 Current Stock",
                    value: quran.stock,
                    inline: true
                  },
                  {
                    name: "🚨 Status",
                    value: "Low Stock - Please restock soon!",
                    inline: true
                  }
                ],
                footer: {
                  text: "Quran Distribution System • #{Time.current.year}"
                },
                timestamp: Time.current.iso8601
              }
            ]
          }
          
          request = Net::HTTP::Post.new(uri.request_uri, {
            'Content-Type' => 'application/json'
          })
          request.body = payload.to_json
          
          response = http.request(request)
          
          NotificationActivity.create(
            title: "Low Stock Notification",
            message: "Low stock alert for #{quran.title}",
            sent_to: settings['discord_webhook_url'],
            status: response.code.to_i == 204 ? 'success' : 'failed'
          )
          
        rescue => e
          NotificationActivity.create(
            title: "Low Stock Notification Failed",
            message: "Error: #{e.message}",
            sent_to: settings['discord_webhook_url'],
            status: 'failed'
          )
        end
      end

      
      def self.send_discord_notification(message, webhook_url)
        return false unless webhook_url.present?
    
        begin
          # Parse the URL to ensure it's valid
          uri = URI.parse(webhook_url)
          
          # Discord expects specific payload format
          payload = {
            content: message,
            username: 'Quran Distribution Bot',
            avatar_url: 'https://cdn-icons-png.flaticon.com/512/210/210626.png',
            embeds: [] # Optional: you can add rich embeds here
          }
    
          puts "=== DISCORD PAYLOAD ===".blue
          puts "URL: #{webhook_url}"
          puts "Message: #{message}"
          puts "=======================".blue
    
          headers = {
            'Content-Type' => 'application/json',
            'User-Agent' => 'QuranDistribution/1.0'
          }
    
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == 'https')
          http.read_timeout = 10
          http.open_timeout = 10
          
          request = Net::HTTP::Post.new(uri.request_uri, headers)
          request.body = payload.to_json
    
          puts "=== SENDING REQUEST ===".green
          response = http.request(request)
          puts "Response Code: #{response.code}"
          puts "Response Body: #{response.body}"
          puts "=======================".green
    
          # Log the activity with more details
          NotificationActivity.create(
            title: "Discord Test Notification",
            message: "Test message sent to Discord",
            sent_to: webhook_url,
            status: response.code.to_i == 204 ? 'success' : 'failed'
          )
    
          # Discord returns 204 No Content on success
          response.code.to_i == 204
          
        rescue URI::InvalidURIError => e
          puts "=== INVALID URL ERROR ===".red
          puts e.message
          NotificationActivity.create(
            title: "Discord Webhook Failed",
            message: "Invalid webhook URL: #{e.message}",
            sent_to: webhook_url,
            status: 'failed'
          )
          false
        rescue => e
          puts "=== GENERAL ERROR ===".red
          puts e.message
          puts e.backtrace.first(5).join("\n")
          NotificationActivity.create(
            title: "Discord Webhook Failed",
            message: "Error: #{e.message}",
            sent_to: webhook_url,
            status: 'failed'
          )
          false
        end
      end
  
    def self.send_whatsapp_notification(message, webhook_url, phone_numbers = [])
      return unless webhook_url.present?
  
      # For WhatsApp Business API or third-party services
      payload = {
        message: message,
        to: phone_numbers, # Array of phone numbers
        platform: 'whatsapp'
      }
  
      send_webhook(webhook_url, payload)
    end
  
    def self.send_generic_webhook(message, webhook_url, custom_payload = {})
      return unless webhook_url.present?
  
      payload = custom_payload.merge(
        message: message,
        timestamp: Time.current.iso8601,
        source: 'quran_distribution_app'
      )
  
      send_webhook(webhook_url, payload)
    end
  
    def self.send_new_order_notification(order)
        settings = load_notification_settings
        
        return unless settings['enable_discord_notifications'] && settings['discord_webhook_url'].present?
    
        require 'net/http'
        require 'uri'
        
        begin
          uri = URI.parse(settings['discord_webhook_url'])
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          # Get Quran title safely
          quran_title = if order.respond_to?(:quran) && order.quran.present?
                          order.quran.title 
                        else
                          "Not specified"
                        end
          
          payload = {
            content: "📦 **NEW QURAN ORDER RECEIVED!**",
            username: 'Quran Distribution Bot',
            avatar_url: 'https://cdn-icons-png.flaticon.com/512/210/210626.png',
            embeds: [
              {
                title: "Order Details",
                color: 3066993, # Green color
                fields: [
                  {
                    name: "🆔 Order ID",
                    value: "##{order.id}",
                    inline: true
                  },
                  {
                    name: "📅 Date",
                    value: order.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                    inline: true
                  },
                  {
                    name: "👤 Customer",
                    value: order.full_name || "Not provided",
                    inline: true
                  },
                  {
                    name: "📧 Email",
                    value: order.email,
                    inline: true
                  },
                  {
                    name: "📞 Phone",
                    value: order.phone || "Not provided",
                    inline: true
                  },
                  {
                    name: "📖 Quran",
                    value: quran_title,
                    inline: true
                  },
                  {
                    name: "📍 Address",
                    value: format_order_address(order),
                    inline: false
                  }
                ],
                footer: {
                  text: "Quran Distribution System • #{Time.current.year}"
                },
                timestamp: order.created_at.iso8601
              }
            ]
          }
          
          request = Net::HTTP::Post.new(uri.request_uri, {
            'Content-Type' => 'application/json'
          })
          request.body = payload.to_json
          
          response = http.request(request)
          
          # Log the activity - FIXED: use full_name instead of name
          NotificationActivity.create(
            title: "New Order Notification",
            message: "Order ##{order.id} - #{order.full_name}",
            sent_to: settings['discord_webhook_url'],
            status: response.code.to_i == 204 ? 'success' : 'failed'
          )
          
          Rails.logger.info "📧 Discord notification sent for order ##{order.id}. Response: #{response.code}"
          
          response.code.to_i == 204
          
        rescue => e
          NotificationActivity.create(
            title: "Order Notification Failed",
            message: "Order ##{order.id} - Error: #{e.message}",
            sent_to: settings['discord_webhook_url'],
            status: 'failed'
          )
          
          Rails.logger.error "❌ Failed to send Discord notification for order ##{order.id}: #{e.message}"
          false
        end
      end
  
    private
  
    def self.send_webhook(url, payload)
      begin
        response = HTTParty.post(url, 
          body: payload.to_json,
          headers: {
            'Content-Type' => 'application/json',
            'User-Agent' => 'QuranDistribution/1.0'
          },
          timeout: 10
        )
        
        # Log the activity
        NotificationActivity.create(
          title: "Webhook Notification Sent",
          message: "Sent to: #{URI.parse(url).host}",
          sent_to: url,
          status: response.success? ? 'success' : 'failed',
        )
  
        response.success?
      rescue => e
        NotificationActivity.create(
          title: "Webhook Notification Failed",
          message: "Error: #{e.message}",
          sent_to: url,
          status: 'failed'
        )
        false
      end
    end

    def self.format_order_address(order)
        address_parts = []
        
        # Safely access address fields
        address_parts << order.address if order.respond_to?(:address) && order.address.present?
        address_parts << order.city if order.respond_to?(:city) && order.city.present?
        address_parts << order.country_code if order.respond_to?(:country_code) && order.country_code.present?
        address_parts << order.postal_code if order.respond_to?(:postal_code) && order.postal_code.present?
        
        if address_parts.empty?
          "Address not provided"
        else
          address_parts.join(', ')
        end
      end
  
    def self.load_notification_settings
      settings_path = Rails.root.join('config', 'notification_settings.yml')
      if File.exist?(settings_path)
        YAML.safe_load(File.read(settings_path), permitted_classes: [Symbol]) || {}
      else
        {}
      end
    end
  end