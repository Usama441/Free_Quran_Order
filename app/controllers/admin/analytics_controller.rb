class Admin::AnalyticsController < ApplicationController
  before_action :authenticate_admin!
  require 'csv'
  def orders
    # Order analytics data
    @total_orders = Order.count
    @orders_today = Order.where('created_at >= ?', Date.today).count
    @orders_this_week = Order.where('created_at >= ?', 1.week.ago).count
    @orders_this_month = Order.where('created_at >= ?', 1.month.ago).count

    # Order trends by time period
    @daily_orders = Order.where('created_at >= ?', 30.days.ago)
                          .group_by_day(:created_at, format: "%m/%d").count
    @weekly_orders = Order.where('created_at >= ?', 12.weeks.ago)
                          .group_by_week(:created_at).count
    @monthly_orders = Order.where('created_at >= ?', 12.months.ago)
                           .group_by_month(:created_at, format: "%b %Y").count

    # Order distribution by quantity
    @quantity_distribution = Order.group(:quantity).count.sort_by { |k, v| k }

    # Average order value (in this case, quantity since all free)
    @avg_quantity_per_order = Order.average(:quantity).round(2)
  end

  def customers
    @unique_customers = Order.distinct.count(:email)
    @repeat_customers_data = Order.group(:email)
                              .having('COUNT(*) > 1')
                              .order(Arel.sql('COUNT(*) DESC'))
                              .count
    @repeat_customers = @repeat_customers_data.keys.count
    @first_time_customers = @unique_customers - @repeat_customers

    # Customer demographics
    @top_countries = Order.group(:country_code).count.sort_by { |k, v| -v }.first(10)
    @customer_emails = Order.pluck(:email).uniq
    
    # Order patterns
    @orders_per_customer = Order.group(:email).count.values.sort.reverse
    @avg_orders_per_customer = (Order.count.to_f / @unique_customers).round(2)
  end

  def geography
    # Geographic analytics data
    @countries_data = Order.group(:country_code).count.map do |country_code, count|
      lat_lng = country_coordinates(country_code)
      {
        country: country_code,
        orders: count,
        lat: lat_lng[:lat],
        lng: lat_lng[:lng]
      }
    end.reject { |c| c[:lat].nil? }.sort_by { |c| -c[:orders] }

    # Regional statistics
    @asian_countries = Order.where(country_code: ['PK', 'IN', 'BD', 'LK', 'NP', 'BT', 'MY', 'ID']).count
    @middle_east_countries = Order.where(country_code: ['AE', 'SA', 'BH', 'QA', 'OM', 'KW', 'IR', 'EG']).count
    @european_countries = Order.where(country_code: ['GB', 'DE', 'FR', 'IT', 'ES', 'TR']).count
    @american_countries = Order.where(country_code: ['US', 'CA']).count
  end

  def reports
    # Calculate correct metrics
    @total_orders = Order.count
    @total_qurans_distributed = Order.where(status: 'delivered').sum(:quantity)
    @current_stock = Quran.sum(:stock)
    @countries_reached = Order.distinct.count(:country_code)

    # Report generation data with correct calculations
    @reports_data = {
      daily: generate_report_data('day', 30),
      weekly: generate_report_data('week', 12),
      monthly: generate_report_data('month', 12)
    }

    # Get recent exports
    @recent_exports = ExportHistory.last(5).reverse

    # Calculate data for display
    @reports = {
      daily: @reports_data[:daily],
      weekly: @reports_data[:weekly],
      monthly: @reports_data[:monthly]
    }
  end


  def generate_daily_report
    start_date = params[:start_date] || Date.today
    end_date = params[:end_date] || Date.today
    
    orders = Order.where(created_at: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
    report_data = generate_custom_report(orders, 'daily')
    
    # Save export history
    ExportHistory.create!(
      report_type: 'daily',
      start_date: start_date,
      end_date: end_date,
      format: params[:format] || 'pdf',
      generated_at: Time.current
    )
    
    respond_to do |format|
      format.pdf { send_data generate_pdf(report_data), filename: "daily_report_#{Date.today}.pdf", type: 'application/pdf' }
      format.csv { send_data generate_csv(report_data), filename: "daily_report_#{Date.today}.csv", type: 'text/csv' }
    end
  end

  def generate_weekly_report
    start_date = params[:start_date] || 1.week.ago.to_date
    end_date = params[:end_date] || Date.today
    
    orders = Order.where(created_at: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
    report_data = generate_custom_report(orders, 'weekly')
    
    ExportHistory.create!(
      report_type: 'weekly',
      start_date: start_date,
      end_date: end_date,
      format: params[:format] || 'pdf',
      generated_at: Time.current
    )
    
    respond_to do |format|
      format.pdf { send_data generate_pdf(report_data), filename: "weekly_report_#{Date.today}.pdf", type: 'application/pdf' }
      format.csv { send_data generate_csv(report_data), filename: "weekly_report_#{Date.today}.csv", type: 'text/csv' }
    end
  end

  def generate_monthly_report
    start_date = params[:start_date] || 1.month.ago.to_date
    end_date = params[:end_date] || Date.today
    
    orders = Order.where(created_at: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
    report_data = generate_custom_report(orders, 'monthly')
    
    ExportHistory.create!(
      report_type: 'monthly',
      start_date: start_date,
      end_date: end_date,
      format: params[:format] || 'pdf',
      generated_at: Time.current
    )
    
    respond_to do |format|
      format.pdf { send_data generate_pdf(report_data), filename: "monthly_report_#{Date.today}.pdf", type: 'application/pdf' }
      format.csv { send_data generate_csv(report_data), filename: "monthly_report_#{Date.today}.csv", type: 'text/csv' }
    end
  end

  def generate_custom_report_action
    start_date = params[:start_date]
    end_date = params[:end_date]
    report_type = params[:report_type]
    include_charts = params[:include_charts] == '1'
    include_raw_data = params[:include_raw_data] == '1'
    include_summary = params[:include_summary] == '1'
    
    if start_date.blank? || end_date.blank?
      redirect_to admin_reports_analytics_path, alert: "Please select both start and end dates."
      return
    end
    
    orders = Order.where(created_at: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
    report_data = generate_custom_report(orders, 'custom')
    
    ExportHistory.create!(
      report_type: 'custom',
      start_date: start_date,
      end_date: end_date,
      format: params[:format] || 'pdf',
      generated_at: Time.current,
      parameters: {
        report_type: report_type,
        include_charts: include_charts,
        include_raw_data: include_raw_data,
        include_summary: include_summary
      }.to_json
    )
    
    respond_to do |format|
      format.pdf { send_data generate_pdf(report_data), filename: "custom_report_#{Date.today}.pdf", type: 'application/pdf' }
      format.csv { send_data generate_csv(report_data), filename: "custom_report_#{Date.today}.csv", type: 'text/csv' }
    end
  end

  def download_csv
    # Generate CSV dynamically from database
    csv_data = generate_complete_csv
    
    ExportHistory.create!(
      report_type: 'complete_export',
      start_date: Order.minimum(:created_at)&.to_date,
      end_date: Date.today,
      format: 'csv',
      generated_at: Time.current
    )
    
    send_data csv_data, filename: "quran_orders_report_#{Date.today.strftime('%Y-%m-%d')}.csv", type: 'text/csv'
  end

  def download_export
    @export = ExportHistory.find(params[:id])
    
    case @export.report_type
    when 'complete_export'
      csv_data = generate_complete_csv
      send_data csv_data, filename: "quran_orders_export_#{@export.generated_at.strftime('%Y-%m-%d')}.csv", type: 'text/csv'
    else
      redirect_to admin_reports_analytics_path, alert: "Export file not available."
    end
  end

  def delete_export
    @export = ExportHistory.find(params[:id])
    @export.destroy
    redirect_to admin_reports_analytics_path, notice: "Export history deleted successfully."
  end


  private

   # ADD THIS MISSING METHOD
   def generate_complete_csv
    CSV.generate(headers: true) do |csv|
      csv << ['Order ID', 'Customer Name', 'Email', 'Phone', 'Country', 'City', 'State', 'Postal Code', 'Quantity', 'Status', 'Quran Title', 'Order Date']
      
      Order.order(created_at: :desc).includes(:quran).find_each do |order|
        csv << [
          order.id,
          order.full_name,
          order.email,
          order.phone,
          order.country_code,
          order.city,
          order.state,
          order.postal_code,
          order.quantity,
          order.status,
          order.quran&.title || 'N/A',
          order.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end

  def generate_report_data(period, count)
    case period
    when 'day'
      Order.where('created_at >= ?', count.days.ago)
           .group_by_day(:created_at, format: "%b %d").count
    when 'week'
      Order.where('created_at >= ?', count.weeks.ago)
           .group_by_week(:created_at, format: "%b %d, %Y").count
    when 'month'
      Order.where('created_at >= ?', count.months.ago)
           .group_by_month(:created_at, format: "%b %Y").count
    end
  end

  def generate_custom_report(orders, report_type)
    {
      report_type: report_type,
      orders_count: orders.count,
      delivered_orders: orders.where(status: 'delivered').count,
      total_qurans_distributed: orders.where(status: 'delivered').sum(:quantity),
      top_countries: orders.group(:country_code).count.sort_by { |k, v| -v }.first(10),
      order_status_distribution: orders.group(:status).count,
      average_quantity: orders.average(:quantity).to_f.round(2),
      orders_data: orders.order(created_at: :desc),
      generated_at: Time.current
    }
  end

  def generate_pdf(report_data)
    begin
      pdf = Prawn::Document.new(page_size: 'A4', page_layout: :portrait)
      
      # Header
      pdf.font_size(20) { pdf.text "Quran Distribution Report", align: :center, style: :bold }
      pdf.move_down 20
      
      # Report details in a table format
      data = [
        ["Report Type:", report_data[:report_type].titleize],
        ["Total Orders:", report_data[:orders_count].to_s],
        ["Delivered Orders:", report_data[:delivered_orders].to_s],
        ["Total Qurans Distributed:", report_data[:total_qurans_distributed].to_s],
        ["Average Quantity per Order:", report_data[:average_quantity].to_s],
        ["Generated:", report_data[:generated_at].strftime('%Y-%m-%d %H:%M')]
      ]
      
      pdf.table(data, width: pdf.bounds.width) do
        cells.padding = 8
        cells.borders = []
        row(0).font_style = :bold
      end
      
      pdf.move_down 20
      
      # Top countries section
      if report_data[:top_countries].any?
        pdf.font_size(16) { pdf.text "Top Countries by Orders", style: :bold }
        pdf.move_down 10
        
        country_data = [["Country", "Orders"]]
        report_data[:top_countries].each do |country, count|
          country_data << [country, count.to_s]
        end
        
        pdf.table(country_data, width: pdf.bounds.width, header: true) do
          row(0).font_style = :bold
          row(0).background_color = "f0f0f0"
          cells.padding = 6
          cells.borders = [:bottom]
        end
      end
      
      pdf.move_down 20
      
      # Order status distribution
      if report_data[:order_status_distribution].any?
        pdf.font_size(16) { pdf.text "Order Status Distribution", style: :bold }
        pdf.move_down 10
        
        status_data = [["Status", "Count"]]
        report_data[:order_status_distribution].each do |status, count|
          status_data << [status ? status.titleize : 'N/A', count.to_s]
        end
        
        pdf.table(status_data, width: pdf.bounds.width, header: true) do
          row(0).font_style = :bold
          row(0).background_color = "f0f0f0"
          cells.padding = 6
          cells.borders = [:bottom]
        end
      end
      
      # Footer
      pdf.move_down 30
      pdf.font_size(10) do
        pdf.text "Generated by Quran Distribution System", align: :center
        pdf.text "Page 1 of 1", align: :center
      end
      
      pdf.render
      
    rescue => e
      # If PDF generation fails, return a simple text message
      Rails.logger.error "PDF Generation Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      # Return a simple valid PDF with error message
      pdf = Prawn::Document.new
      pdf.text "PDF Generation Error", size: 16, style: :bold
      pdf.move_down 10
      pdf.text "There was an error generating the PDF report."
      pdf.text "Please try downloading the CSV format instead."
      pdf.text "Error: #{e.message}"
      pdf.render
    end
  end
  def generate_csv(report_data)
    CSV.generate(headers: true) do |csv|
      csv << ['Report Type', report_data[:report_type].titleize]
      csv << ['Total Orders', report_data[:orders_count]]
      csv << ['Delivered Orders', report_data[:delivered_orders]]
      csv << ['Total Qurans Distributed', report_data[:total_qurans_distributed]]
      csv << ['Average Quantity', report_data[:average_quantity]]
      csv << ['Generated At', report_data[:generated_at].strftime('%Y-%m-%d %H:%M')]
      csv << []
      csv << ['Top Countries', 'Order Count']
      report_data[:top_countries].each do |country, count|
        csv << [country, count]
      end
      csv << []
      csv << ['Order Status', 'Count']
      report_data[:order_status_distribution].each do |status, count|
        csv << [status ? status.titleize : 'N/A', count]
      end
    end
  end
  
  def country_coordinates(country_code)
    coordinates = {
      'PK' => { lat: 30.3753, lng: 69.3451 },  # Pakistan
      'US' => { lat: 37.0902, lng: -95.7129 },  # USA
      'GB' => { lat: 55.3781, lng: -3.4360 },  # UK
      'AE' => { lat: 23.4241, lng: 53.8478 },  # UAE
      'SA' => { lat: 23.8859, lng: 45.0792 },  # Saudi Arabia
      'BH' => { lat: 25.9304, lng: 50.6378 },  # Bahrain
      'QA' => { lat: 25.3548, lng: 51.1839 },  # Qatar
      'OM' => { lat: 21.4735, lng: 55.9754 },  # Oman
      'KW' => { lat: 29.3117, lng: 47.4818 },  # Kuwait
      'EG' => { lat: 26.0963, lng: 29.9788 },  # Egypt
      'IN' => { lat: 20.5937, lng: 78.9629 },  # India
      'AF' => { lat: 33.9391, lng: 67.7100 },  # Afghanistan
      'IR' => { lat: 32.4279, lng: 53.6880 },  # Iran
      'CA' => { lat: 56.1304, lng: -106.3468 }, # Canada
      'AU' => { lat: -25.2744, lng: 133.7751 }, # Australia
      'DE' => { lat: 51.1657, lng: 10.4515 },  # Germany
      'FR' => { lat: 46.2276, lng: 2.2137 },   # France
      'IT' => { lat: 41.8719, lng: 12.5674 },  # Italy
      'ES' => { lat: 40.4637, lng: -3.7492 },  # Spain
      'TR' => { lat: 38.9637, lng: 35.2433 },  # Turkey
      'MY' => { lat: 4.2105, lng: 101.9758 },  # Malaysia
      'ID' => { lat: -0.7893, lng: 113.9213 }, # Indonesia
      'BD' => { lat: 23.6850, lng: 90.3563 },  # Bangladesh
      'LK' => { lat: 7.8731, lng: 80.7718 },   # Sri Lanka
      'NP' => { lat: 28.3949, lng: 84.1240 },  # Nepal
      'BT' => { lat: 27.5142, lng: 90.4336 },  # Bhutan
      'MV' => { lat: 3.2028, lng: 73.2207 }    # Maldives
    }
    coordinates[country_code.upcase] || { lat: nil, lng: nil }
  end
end




