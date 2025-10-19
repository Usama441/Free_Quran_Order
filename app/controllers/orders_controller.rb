class OrdersController < ApplicationController
  def new
    @quran = Quran.find_by(id: params[:quran_id])
    @order = Order.new(quran: @quran)
     # If a specific Quran is selected, use its details
     if @quran
      @order.translation = @quran.translation
    else
      # Default values if no specific Quran selected
      @order.translation = 'english'
    end
    # Initialize countries data
    @countries_data = load_countries_data
    @phone_formats = load_phone_formats
  end


  def create  
    @order = Order.new(order_params)
    @order.quantity ||= 1 # Default quantity

    respond_to do |format|
      if @order.save
        # Trigger background job for admin notification
        OrderBroadcastJob.perform_later(@order)

        format.html { redirect_to order_create_success_path, notice: "Thank you for your order request! We'll send you your free Quran copy soon." }
        format.json { render json: { success: true, message: "Order submitted successfully!" }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @order.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def create_success
  end

  private

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
