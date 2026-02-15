Rails.application.routes.draw do
  # Setup (first-run only)
  resource :setup, only: [ :new, :create ], controller: "setup"

  # Authentication
  resource :session

  # Settings (admin only)
  resource :settings, only: [ :show ] do
    post :regenerate_invite_token, on: :member
  end

  # Profile
  resource :profile, only: [ :show, :update ]

  # User management (admin only)
  resources :users, only: [ :update, :destroy ]

  # User search (for DMs)
  resources :user_searches, only: [ :index ]

  # Direct messages
  resources :direct_messages, only: [ :create ]

  # Join via invite link
  get "join/:token", to: "join#show", as: :join
  post "join/:token", to: "join#create"

  # Chat
  resources :rooms, only: [ :show ] do
    resources :messages, only: [ :create, :update, :destroy ]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "home#index"
end
