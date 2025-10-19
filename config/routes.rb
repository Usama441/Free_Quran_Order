Rails.application.routes.draw do
  # Main site homepage
  root "home#index"

# Public order routes
resources :orders, only: [:new, :create]
get "orders/create", to: "orders#create_success", as: :create_success

  # Admin namespace for custom controllers (e.g., Qurans management)
  namespace :admin do
    # Use proper RESTful routes for Qurans
    resources :qurans, except: [:show]

    # Order management
    resources :orders, only: [:index, :show] do
      collection do
        get :export_csv
      end
      member do
        patch :update_status
      end
    end
    # Admin dashboard and analytics
    get "dashboard", to: "dashboard#index", as: :dashboard
    get "analytics/orders", to: "analytics#orders", as: :order_analytics
    get "analytics/customers", to: "analytics#customers", as: :customer_analytics
    get "analytics/geography", to: "geography#show", as: :geographic_analytics
    get "analytics/reports", to: "analytics#reports", as: :reports
    post "analytics/reports/download_csv", to: "analytics#download_csv", as: :download_csv_reports
    get "settings/configuration", to: "settings#configuration", as: :configuration
    get "settings/notifications", to: "settings#notifications", as: :notifications
  end

  # Devise routes for Admin (authentication) with custom sessions controller
  devise_for :admins, path: 'admin', controllers: { sessions: 'admin/sessions' }
end
