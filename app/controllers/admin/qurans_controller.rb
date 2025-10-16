class Admin::QuransController < ApplicationController
  before_action :authenticate_admin!
  before_action :set_quran, only: [:edit, :update, :destroy]

  def index
    @qurans = Quran.all.order(created_at: :desc)
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

  def edit; end

  def update
    if @quran.update(quran_params)
      redirect_to admin_qurans_path, notice: "Quran updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quran.destroy
    redirect_to admin_qurans_path, notice: "Quran deleted successfully."
  end

  private

  def set_quran
    @quran = Quran.find(params[:id])
  end

  def quran_params
    params.require(:quran).permit(:title, :writer, :translation, :pages, :stock, :description)
  end
end
