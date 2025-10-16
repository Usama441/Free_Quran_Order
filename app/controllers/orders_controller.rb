class OrdersController < ApplicationController
  def new
    @order = Order.new
    @quran = Quran.find_by(id: params[:quran_id])
  end


  def create
    @order = Order.new(order_params)

    if @order.country_code.present? && @order.phone.present?
      @order.phone = "#{@order.country_code} #{@order.phone}"
    end

    if @order.save
      redirect_to root_path, notice: "Your order has been received!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:full_name, :email, :phone, :country_code, :city, :state, :postal_code, :address, :quantity, :note)
  end
end
