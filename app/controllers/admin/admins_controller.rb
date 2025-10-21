class Admin::AdminsController < ApplicationController
  before_action :authenticate_admin!
  before_action :authorize_super_admin!
  before_action :set_admin, only: [:edit, :update, :destroy]

  def index
    @admins = Admin.all.order(:email)
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)

    if @admin.save
      redirect_to admin_admins_path, notice: "Admin user was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @admin = Admin.find(params[:id])
  end

  def update
    @admin = Admin.find(params[:id])

    # Prevent self-demotion or promotion of super_admins
    if @admin.super_admin? && params[:admin][:role] == "manager" && @admin == current_admin
      redirect_to admin_admins_path, alert: "You cannot demote yourself from super admin."
      return
    end

    if @admin.update(admin_params)
      redirect_to admin_admins_path, notice: "Admin user was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @admin = Admin.find(params[:id])

    # Prevent self-deletion
    if @admin == current_admin
      redirect_to admin_admins_path, alert: "You cannot delete your own account."
      return
    end

    if @admin.destroy
      redirect_to admin_admins_path, notice: "Admin user was successfully deleted."
    else
      redirect_to admin_admins_path, alert: "Failed to delete admin user."
    end
  end

  private

  def authorize_super_admin!
    unless current_admin.super_admin?
      redirect_to admin_dashboard_path, alert: "Access denied. Super admin privileges required."
    end
  end

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def admin_params
    params.require(:admin).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role)
  end
end
