class Admin::OrdersController < ApplicationController
  layout 'admin'
  before_action :authenticate_admin!
  before_action :set_order, only: [:show, :update_status]

  def index
    @orders = Order.includes(:quran).order(created_at: :desc)

    # Search by order ID if provided
    if params[:search].present?
      @orders = @orders.where('orders.id = ?', params[:search])
    end

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
      format.json { render json: { html: render_to_string(partial: 'orders_table', formats: [:html]), pending_count: @pending_count, processing_count: @processing_count, shipped_count: @shipped_count, delivered_count: @delivered_count } }
    end
  end

  def show
    @order = Order.includes(:quran).find(params[:id])
  end

  def update_status
    # Handle the status parameter properly
    status_param = params[:status]
    if @order.update(status: status_param)
      respond_to do |format|
        format.html { redirect_to admin_orders_path, notice: "Order status updated successfully." }
        format.json { render json: { success: true, message: "Status updated.", new_status: @order.status } }
      end
    else
      respond_to do |format|
        format.html { redirect_to admin_orders_path, alert: "Failed to update order status." }
        format.json { render json: { success: false, error: @order.errors.full_messages.join(', ') }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end
end
