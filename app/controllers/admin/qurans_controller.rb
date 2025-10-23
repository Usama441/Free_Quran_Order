class Admin::QuransController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_quran, only: [:show, :edit, :update, :destroy]


  def index
    @qurans = Quran.all.order(created_at: :desc)

    # Pagination setup
    @per_page_options = [10, 20, 50, 100]
    @per_page = (params[:per_page] || 20).to_i

    @qurans = @qurans.page(params[:page]).per(@per_page)
  end

  def new
    @quran = Quran.new
  end

  def create
    @quran = Quran.new(quran_params)
    if @quran.save
      redirect_to admin_qurans_path, notice: "Quran successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    # Handle image removal if requested
    if params[:remove_image].present?
      params[:remove_image].each do |signed_id|
        begin
          # Find and purge the specific attachment
          @quran.images.find { |img| img.blob.signed_id == signed_id }&.purge_later
        rescue => e
          Rails.logger.error "Failed to remove image #{signed_id}: #{e.message}"
          # Continue with other operations
        end
      end
    end

    if @quran.update(quran_params)
      redirect_to admin_qurans_path, notice: "Quran updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @quran.destroy
      redirect_to admin_qurans_path, notice: "Quran deleted successfully."
    else
      redirect_to admin_qurans_path, alert: "Failed to delete Quran. It may be referenced by existing orders."
    end
  end

  private

  def set_quran
    @quran = Quran.find(params[:id])
  end

  def quran_params
    params.require(:quran).permit(:title, :writer, :translation, :pages, :stock, :description, images: [])
  end

  def set_cache_headers
    # Prevent caching for admin actions to ensure fresh data
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    # But cache static assets
    response.headers['Cache-Control'] += ', public' unless request.get?
  end
end
