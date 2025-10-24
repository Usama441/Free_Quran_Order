require 'csv'

class Admin::OrdersController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_order, only: [:show, :update_status]

  def index
    @orders = Order.includes(:quran).order(created_at: :desc)

    # Filter by status if provided using numeric values for enum - for AJAX calls
    if params[:status].present?
      status_value = Order.statuses[params[:status]]
      @orders = @orders.where(status: status_value) if status_value.present?
    end

    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      @orders = @orders.where(created_at: params[:start_date]..params[:end_date])
    end

    # Use database integer values for enum counts
    @pending_count = Order.where(status: Order.statuses['pending']).count
    @processing_count = Order.where(status: Order.statuses['processing']).count
    @shipped_count = Order.where(status: Order.statuses['shipped']).count
    @delivered_count = Order.where(status: Order.statuses['delivered']).count

    respond_to do |format|
      format.html # For full page loads
      format.json do 
        render json: { html: render_to_string(partial: 'orders_table', formats: [:html]),   pending_count: @pending_count,   processing_count: @processing_count,   shipped_count: @shipped_count,   delivered_count: @delivered_count }    
      end
    end
  end

  def export_csv
    @orders = Order.order(created_at: :desc)

    # Apply same filters as index
    if params[:status].present?
      status_value = Order.statuses[params[:status]]
      @orders = @orders.where(status: status_value) if status_value.present?
    end

    if params[:start_date].present? || params[:end_date].present?
      start_date = params[:start_date].presence || Date.new(2000, 1, 1)
      end_date = params[:end_date].presence || Date.today
      @orders = @orders.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        "ID",
        "Full Name",
        "Email",
        "Phone",
        "Address",
        "Quantity",
        "Status",
        "Tracking Number",
        "Email Verified",
        "Phone Verified",
        "City",
        "State",
        "Postal Code",
        "Quran Name",
        "Translation",
        "Created At",
        "Note"
      ]
    
      @orders.each do |order|
        csv << [
          order.id,
          order.full_name,
          order.email,
          "#{order.country_code}#{order.phone}", # combined country code + phone
          order.address,
          order.quantity,
          order.status ? order.status.titleize : "N/A",
          order.tracking_number,
          order.email_verified,
          order.phone_verified,
          order.city,
          order.state,
          order.postal_code,
          order.quran&.title, # assuming belongs_to :quran
          order.translation,
          order.created_at.strftime("%Y-%m-%d %H:%M"),
          order.note
        ]
      end
    end
    

    send_data csv_data,
              filename: "orders_#{Time.zone.now.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def show
    @order = Order.includes(:quran).find(params[:id])
    puts @order
  end

  def update_status
    # Handle the status parameter properly
    status_param = params[:status]
    if @order.update(status: status_param)
      respond_to do |format|
        format.json { render json: { success: true, message: "Status updated.", new_status: @order.status } }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, error: @order.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end
end
