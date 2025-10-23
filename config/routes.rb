Rails.application.routes.draw do
  # Main site homepage
  root "home#index"

  # Public order routes
  resources :orders, only: [:new, :create]
  get "orders/create", to: "orders#create_success", as: :create_success

  # About page
  get "about", to: "home#about"

  # Admin namespace for custom controllers (e.g., Qurans management)
  namespace :admin do
    # Admin user management (super admin only)
    resources :admins

    # Use proper RESTful routes for Qurans
    resources :qurans

    # Order management
    get "orders", to: "orders#index", as: :orders
    get "orders/:id", to: "orders#show", as: :order
    patch "orders/:id/status", to: "orders#update_status", as: :update_order_status

    # Admin dashboard and analytics
    root to: "dashboard#index", as: :root
    get "dashboard", to: "dashboard#index", as: :dashboard
    get "analytics/orders", to: "analytics#orders", as: :order_analytics
    get "analytics/customers", to: "analytics#customers", as: :customer_analytics
    get "analytics/geography", to: "geography#show", as: :geographic_analytics
    get "analytics/reports", to: "analytics#reports", as: :reports
    post "analytics/reports/download_csv", to: "analytics#download_csv", as: :download_csv_reports
    get "settings/configuration", to: "settings#configuration", as: :configuration
    get "settings/notifications", to: "settings#notifications", as: :notifications
    delete "settings/clear_notification_history", to: "settings#clear_notification_history", as: :clear_notification_history
  end

  # Devise routes for Admin (authentication) with custom sessions controller
  devise_for :admins, path: 'admin', controllers: { sessions: 'admin/sessions' }

  # PWA routes
  get '/service-worker.js' => 'pwa#service_worker'
end
