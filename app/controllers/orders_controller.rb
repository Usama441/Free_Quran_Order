class OrdersController < ApplicationController
  include SettingsHelper
  before_action :check_maintenance_mode, except: [:create_success]
  before_action :check_order_limits, only: [:create]
  before_action :log_debug_info, if: :debug_mode?

  def new
    @quran = Quran.find_by(id: params[:quran_id])
    @order = Order.new(quran: @quran)
     # If a specific Quran is selected, use its details
     if @quran
      @order.translation = @quran.translation
    else
      # Default values if no specific Quran selected
      @order.translation = default_translation
    end
    # Initialize countries data
    @countries_data = load_countries_data
    @phone_formats = load_phone_formats

    @daily_order_info = get_daily_order_info

    log_debug_action('new_order_page_loaded', {
      quran_id: params[:quran_id],
      default_translation: default_translation,
      maintenance_mode: maintenance_mode?,
      debug_mode: debug_mode?,
      daily_orders: @daily_order_info[:today_count],
      daily_limit: @daily_order_info[:daily_limit]
    })
  end


  def create  
    @order = Order.new(order_params)
    @order.quantity ||= 1 # Default quantity
    
    #Debug: Log order creation attempt
    log_debug_action('order_creation_attempt', {
      order_params: order_params.to_h,
      daily_orders: today_orders_count,
      daily_limit: max_daily_orders,
      maintenance_mode: maintenance_mode?
    })

    # Check if we've reached daily limits (redundant check for safety)
    if daily_order_limit_reached?

      log_debug_action('order_rejected_daily_limit', {
        daily_orders: today_orders_count,
        daily_limit: max_daily_orders
      })
      
      respond_to do |format|
        format.html do 
          redirect_to new_order_path, 
          alert: "We've reached our daily order limit. Please try again tomorrow."
        end
        format.json do 
          render json: { 
            success: false, 
            errors: ["We've reached our daily order limit. Please try again tomorrow."] 
          }, status: :unprocessable_entity 
        end
      end
      return
    end

    respond_to do |format|
      if @order.save

        # Debug: Log successful order creation
        log_debug_action('order_created_successfully', {
          order_id: @order.id,
          order_email: @order.email,
          daily_orders: today_orders_count,
          remaining_orders: max_daily_orders - today_orders_count
        })

        # Trigger background job for admin notification
        OrderBroadcastJob.perform_later(@order)

        # if @daily_order_info[:remaining] <= 5
        #   AdminNotificationJob.perform_later(
        #     "Low Order Capacity", 
        #     "Only #{@daily_order_info[:remaining]} orders remaining today. Total: #{@daily_order_info[:today_count]}/#{@daily_order_info[:daily_limit]}")
        # end

        format.html { redirect_to order_create_success_path, notice: "Thank you for your order request! We'll send you your free Quran copy soon." }
        format.json { render json: { success: true, message: "Order submitted successfully!" }, status: :created }
      else
        # Debug: Log order creation errors
        log_debug_action('order_creation_failed', {
          errors: @order.errors.full_messages,
          order_params: order_params.to_h
        })

        # Re-initialize for the form in case of errors
        @countries_data = load_countries_data
        @phone_formats = load_phone_formats
        @daily_order_info = get_daily_order_info
        
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def create_success
    @daily_order_info = get_daily_order_info

      # Debug information
      log_debug_action('order_success_page_loaded', {
        daily_orders: @daily_order_info[:today_count],
        daily_limit: @daily_order_info[:daily_limit]
      })
  end

  private
  def check_maintenance_mode
    if maintenance_mode?
      log_debug_action('maintenance_mode_redirect', {
        action: action_name,
        controller: controller_name
      })
      
      respond_to do |format|
        format.html do
          render 'maintenance', status: :service_unavailable, layout: 'application'
        end
        format.json do
          render json: { 
            success: false, 
            error: "System is under maintenance. Please try again later." 
          }, status: :service_unavailable
        end
      end
    end
  end

  def check_order_limits
    if daily_order_limit_reached?
      log_debug_action('order_limit_check_failed', {
        daily_orders: today_orders_count,
        daily_limit: max_daily_orders
      })
      
      respond_to do |format|
        format.html do 
          redirect_to new_order_path, 
          alert: "We've reached our daily order limit. Please try again tomorrow."
        end
        format.json do 
          render json: { 
            success: false, 
            errors: ["We've reached our daily order limit. Please try again tomorrow."] 
          }, status: :unprocessable_entity 
        end
      end
    end
  end

  def daily_order_limit_reached?
    today_orders_count >= max_daily_orders
  end

  def today_orders_count
    Order.where(created_at: Time.current.beginning_of_day..Time.current.end_of_day).count
  end

  def get_daily_order_info
    today_count = today_orders_count
    limit = max_daily_orders
    remaining = [limit - today_count, 0].max
    
    {
      today_count: today_count,
      daily_limit: limit,
      remaining: remaining,
      limit_reached: today_count >= limit
    }
  end

  def log_debug_info
    return unless debug_mode?
    
    safe_params = safe_params_to_hash
    logger.info "DEBUG MODE: OrdersController##{action_name} - Params: #{safe_params}"
  end

  def log_debug_action(action, data = {})
    return unless debug_mode?
    
    debug_info = {
      timestamp: Time.current.iso8601,
      controller: 'OrdersController',
      action: action,
      ip: request.remote_ip,
      user_agent: request.user_agent
    }.merge(data)
    
    # Convert any complex objects to strings to avoid serialization issues
    sanitized_debug_info = debug_info.transform_values do |value|
      if value.respond_to?(:to_hash)
        safe_params_to_hash(value)
      else
        value
      end
    end
    
    logger.info "DEBUG: #{sanitized_debug_info.to_json}"
    
    # Also output to console in development
    puts "🔍 DEBUG: #{sanitized_debug_info.to_json}" if Rails.env.development?
  end

  # Safe method to convert parameters to hash
  def safe_params_to_hash(params_obj = nil)
    params_to_convert = params_obj || params
    
    if params_to_convert.respond_to?(:to_unsafe_h)
      # For ActionController::Parameters, use to_unsafe_h with permit!
      params_to_convert.to_unsafe_h.to_h
    elsif params_to_convert.respond_to?(:to_h)
      # For other hash-like objects
      params_to_convert.to_h
    else
      # Fallback to string representation
      params_to_convert.inspect
    end
  rescue => e
    # If anything fails, return a safe representation
    { error: "Could not convert params: #{e.message}" }
  end

  # Alternative simpler method for basic parameter logging
  def safe_params_log
    {
      controller: params[:controller],
      action: params[:action],
      id: params[:id],
      quran_id: params[:quran_id]
    }.compact
  end

  def order_params
    params.require(:order).permit(:full_name, :email, :phone, :country_code, :city, :state, :postal_code, :address, :quantity, :note, :quran_id, :translation)
  end


  def load_countries_data
    # Use a simple static list to avoid API issues - includes major Islamic and global countries
    [
      { name: "United States", code: "US", flag: "🇺🇸", calling_code: "+1" },
      { name: "United Kingdom", code: "GB", flag: "🇬🇧", calling_code: "+44" },
      { name: "Pakistan", code: "PK", flag: "🇵🇰", calling_code: "+92" },
      { name: "India", code: "IN", flag: "🇮🇳", calling_code: "+91" },
      { name: "United Arab Emirates", code: "AE", flag: "🇦🇪", calling_code: "+971" },
      { name: "Saudi Arabia", code: "SA", flag: "🇸🇦", calling_code: "+966" },
      { name: "Canada", code: "CA", flag: "🇨🇦", calling_code: "+1" },
      { name: "Australia", code: "AU", flag: "🇦🇺", calling_code: "+61" },
      { name: "Germany", code: "DE", flag: "🇩🇪", calling_code: "+49" },
      { name: "France", code: "FR", flag: "🇫🇷", calling_code: "+33" },
      { name: "Italy", code: "IT", flag: "🇮🇹", calling_code: "+39" },
      { name: "Spain", code: "ES", flag: "🇪🇸", calling_code: "+34" },
      { name: "Turkey", code: "TR", flag: "🇹🇷", calling_code: "+90" },
      { name: "Malaysia", code: "MY", flag: "🇲🇾", calling_code: "+60" },
      { name: "Indonesia", code: "ID", flag: "🇮🇩", calling_code: "+62" },
      { name: "Bangladesh", code: "BD", flag: "🇧🇩", calling_code: "+880" },
      { name: "Sri Lanka", code: "LK", flag: "🇱🇰", calling_code: "+94" },
      { name: "Nepal", code: "NP", flag: "🇳🇵", calling_code: "+977" },
      { name: "Bhutan", code: "BT", flag: "🇧🇹", calling_code: "+975" },
      { name: "Maldives", code: "MV", flag: "🇲🇻", calling_code: "+960" },
      { name: "Afghanistan", code: "AF", flag: "🇦🇫", calling_code: "+93" },
      { name: "Iran", code: "IR", flag: "🇮🇷", calling_code: "+98" },
      { name: "Bahrain", code: "BH", flag: "🇧🇭", calling_code: "+973" },
      { name: "Qatar", code: "QA", flag: "🇶🇦", calling_code: "+974" },
      { name: "Oman", code: "OM", flag: "🇴🇲", calling_code: "+968" },
      { name: "Kuwait", code: "KW", flag: "🇰🇼", calling_code: "+965" },
      { name: "Egypt", code: "EG", flag: "🇪🇬", calling_code: "+20" }
    ]
  end

  def load_phone_formats
    {
      'US' => { placeholder: '(555) 123-4567', format: 'national', hint: 'Format: (555) 123-4567' },
      'GB' => { placeholder: '7911 123456', format: 'national', hint: 'Format: 7911 123456' },
      'PK' => { placeholder: '300 1234567', format: 'national', hint: 'Format: 300 1234567' },
      'AE' => { placeholder: '50 123 4567', format: 'national', hint: 'Format: 50 123 4567' },
      'SA' => { placeholder: '55 123 4567', format: 'national', hint: 'Format: 55 123 4567' },
      'IN' => { placeholder: '98765 43210', format: 'national', hint: 'Format: 98765 43210' },
      'CA' => { placeholder: '(555) 123-4567', format: 'national', hint: 'Format: (555) 123-4567' },
      'AU' => { placeholder: '412 345 678', format: 'national', hint: 'Format: 412 345 678' },
      'DE' => { placeholder: '151 12345678', format: 'national', hint: 'Format: 151 12345678' },
      'FR' => { placeholder: '6 12 34 56 78', format: 'national', hint: 'Format: 6 12 34 56 78' },
      'IT' => { placeholder: '312 345 6789', format: 'national', hint: 'Format: 312 345 6789' },
      'ES' => { placeholder: '612 345 678', format: 'national', hint: 'Format: 612 345 678' },
      'TR' => { placeholder: '532 123 4567', format: 'national', hint: 'Format: 532 123 4567' },
      'MY' => { placeholder: '12-345 6789', format: 'national', hint: 'Format: 12-345 6789' },
      'ID' => { placeholder: '812-3456-7890', format: 'national', hint: 'Format: 812-3456-7890' },
      'BD' => { placeholder: '1812 345678', format: 'national', hint: 'Format: 1812 345678' },
      'LK' => { placeholder: '77 123 4567', format: 'national', hint: 'Format: 77 123 4567' },
      'NP' => { placeholder: '9841 234567', format: 'national', hint: 'Format: 9841 234567' },
      'BT' => { placeholder: '17 12 34 56', format: 'national', hint: 'Format: 17 12 34 56' },
      'MV' => { placeholder: '771 2345', format: 'national', hint: 'Format: 771 2345' },
      'AF' => { placeholder: '70 123 4567', format: 'national', hint: 'Format: 70 123 4567' },
      'IR' => { placeholder: '912 345 6789', format: 'national', hint: 'Format: 912 345 6789' },
      'BH' => { placeholder: '3600 1234', format: 'national', hint: 'Format: 3600 1234' },
      'QA' => { placeholder: '3312 3456', format: 'national', hint: 'Format: 3312 3456' },
      'OM' => { placeholder: '9212 3456', format: 'national', hint: 'Format: 9212 3456' },
      'KW' => { placeholder: '500 12345', format: 'national', hint: 'Format: 500 12345' },
      'EG' => { placeholder: '10 1234 5678', format: 'national', hint: 'Format: 10 1234 5678' }
    }
  end
end
