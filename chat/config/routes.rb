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

  # Push notifications
  resources :push_subscriptions, only: [ :create, :destroy ] do
    get :vapid_public_key, on: :collection
  end

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
  resources :rooms, only: [ :index, :show, :create, :destroy ] do
    resources :messages, only: [ :create, :update, :destroy ]
    resources :memberships, only: [ :create, :destroy ]
  end

  # PWA
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "home#index"
end
