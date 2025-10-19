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

    # Reports routes - pointing to AnalyticsController
    resources :reports, only: [:index], controller: 'analytics' do
      collection do
        post 'download_csv'
        get 'generate_daily_report'
        get 'generate_weekly_report' 
        get 'generate_monthly_report'
        post 'generate_custom_report_action'
        get 'download_export'
        delete 'delete_export'
      end
    end

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
    get "analytics/reports", to: "analytics#reports", as: :reports_analytics
    get "geography", to: "geography#show", as: :geography
    # get "settings/configuration", to: "settings#configuration", as: :configuration
    # get "settings/notifications", to: "settings#notifications", as: :notifications
    get 'settings/configuration', to: 'settings#configuration', as: 'configuration'
  patch 'settings/configuration', to: 'settings#configuration'
  get 'settings/notifications', to: 'settings#notifications', as: 'notifications'
  patch 'settings/notifications', to: 'settings#notifications'
  end

  # Devise routes for Admin (authentication) with custom sessions controller
  devise_for :admins, path: 'admin', controllers: { sessions: 'admin/sessions' }
end