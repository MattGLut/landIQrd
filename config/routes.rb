Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resource :dashboard, only: [ :show ], controller: "dashboard"
  resource :account, only: [ :show, :edit, :update ], controller: "accounts" do
    get :notifications
    patch :notifications, action: :update_notifications
  end

  get "invites/:token", to: "lease_invitations#show", as: :invite

  resources :properties do
    resources :units, only: [ :new, :create ]
  end

  resources :units, only: [ :show, :edit, :update, :destroy ] do
    resources :leases, only: [ :new, :create ]
    resources :lease_invitations, only: [ :new, :create ]
  end

  resources :leases, only: [ :show, :edit, :update, :destroy ]

  resources :work_orders do
    collection do
      get :schedule
    end
    member do
      post :close
    end
    resources :work_order_assignments, only: [ :create, :update, :destroy ]
  end

  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
  end

  resources :contractors, only: [ :index, :show ]

  namespace :contractor do
    resource :business_profile, only: [ :edit, :update ]
    resources :portfolio_items, except: [ :show ]
  end

  namespace :admin do
    root to: "dashboard#show"
    resource :dashboard, only: [ :show ], controller: "dashboard"
    resources :users
    resources :properties, only: [ :index, :show ]
    resources :work_orders, only: [ :index, :show ]
    resources :conversations, only: [ :index, :show ]
  end

  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  root to: redirect("/users/sign_in")
end
