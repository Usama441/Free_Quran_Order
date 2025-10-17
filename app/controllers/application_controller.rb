# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  layout :set_layout
  # Redirect admin after login
  def after_sign_in_path_for(resource)
    if resource.is_a?(Admin)
      admin_dashboard_path  # <-- Replace with your actual dashboard route
    else
      super
    end
  end

  private

  def set_layout
    if request.path.start_with?('/admin')
      'admin'
    else
      'application'
    end
  end
end