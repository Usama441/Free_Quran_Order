# app/controllers/admin/sessions_controller.rb

  class Admin::SessionsController < Devise::SessionsController
    # GET /admin/sign_in
    def new
      super
    end

    # POST /admin/sign_in
    def create
      super
    end

    # DELETE /admin/sign_out
    def destroy
      super
    end

    protected

    # Redirect admin after login
    def after_sign_in_path_for(resource)
      admin_dashboard_path # <- make sure this route exists
    end

    # Redirect after logout - Admin should go to admin sign-in page, not main site
    def after_sign_out_path_for(resource_or_scope)
      new_admin_session_path
    end
  end
