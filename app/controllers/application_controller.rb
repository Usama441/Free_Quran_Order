# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Redirect admin after login
  def after_sign_in_path_for(resource)
    if resource.is_a?(Admin)
      admin_dashboard_path  # <-- Replace with your actual dashboard route
    else
      super
    end
  end
end