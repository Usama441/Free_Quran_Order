Rails.application.routes.draw do
  # Main site homepage
  root "home#index"

  # Public order routes
  resources :orders, only: [:new, :create]

  # Admin namespace for custom controllers (e.g., Qurans management)
  namespace :admin do
    # Use proper RESTful routes for Qurans
    resources :qurans, except: [:show]

    # Admin dashboard
    get "dashboard", to: "dashboard#index", as: :dashboard
  end

  # Devise routes for Admin (authentication) with custom sessions controller
  devise_for :admins, path: 'admin', controllers: { sessions: 'admin/sessions' }
end