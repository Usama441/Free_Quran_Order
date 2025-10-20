# app/services/webhook_notification_service.rb
class WebhookNotificationService

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
          
          NotificationService.send_low_stock_alert(quran.translation, quran.stock, settings['low_stock_threshold'])
        rescue => e
          NotificationActivity.create(
            title: "Low Stock Notification Failed",
            message: "Error: #{e.message}",
            sent_to: settings['discord_webhook_url'],
            status: 'failed'
          )
        end
    end


  def self.send_daily_summary_notification(orders)
    settings = load_notification_settings
    return unless settings['email_daily_summary'] && settings['discord_webhook_url'].present?

    require 'net/http'
    require 'uri'
    
    begin
      uri = URI.parse(settings['discord_webhook_url'])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      # Calculate order status counts
      pending_count = orders.where(status: 'pending').count
      processing_count = orders.where(status: 'processing').count
      delivered_count = orders.where(status: 'delivered').count
      
      payload = {
        content: "📊 **DAILY ORDER SUMMARY**",
        username: 'Quran Distribution Bot',
        avatar_url: 'https://cdn-icons-png.flaticon.com/512/210/210626.png',
        embeds: [
          {
            title: "Daily Order Report - #{Date.yesterday.strftime('%Y-%m-%d')}",
            color: 3447003, # Blue color for daily summary
            fields: [
              {
                name: "📦 Total Orders",
                value: orders.length.to_s,
                inline: true
              },
              {
                name: "🕒 Pending",
                value: pending_count.to_s,
                inline: true
              },
              {
                name: "⏳ In Progress",
                value: processing_count.to_s,
                inline: true
              },
              {
                name: "✅ Delivered",
                value: delivered_count.to_s,
                inline: true
              },
              {
                name: "📊 Success Rate",
                value: "#{(delivered_count.to_f / orders.length * 100).round(1)}%",
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
      
      # FIX: Pass the orders count, not undefined variable
      NotificationService.send_daily_summary(orders.length)
      
      Rails.logger.info "📊 Daily summary Discord notification sent. Response: #{response.code}"
      response.code.to_i == 204
      
    rescue => e
      NotificationActivity.create(
        title: "Daily Summary Notification Failed",
        message: "Error: #{e.message}",
        sent_to: settings['discord_webhook_url'],
        status: 'failed'
      )
      false
    end
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
          
          # Log the activity
          NotificationService.send_new_order(order)
          
          Rails.logger.info "📧 Discord notification sent for order ##{order.id}. Response: #{response.code}"
          
          response.code.to_i == 204
          
        rescue => e
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