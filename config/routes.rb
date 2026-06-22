Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resource :dashboard, only: [ :show ], controller: "dashboard"

  resources :properties do
    resources :units, only: [ :new, :create ]
  end

  resources :units, only: [ :show, :edit, :update, :destroy ] do
    resources :leases, only: [ :new, :create ]
  end

  resources :leases, only: [ :show, :edit, :update, :destroy ]

  resources :work_orders do
    resources :work_order_assignments, only: [ :create, :update, :destroy ]
  end

  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
  end

  namespace :admin do
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
