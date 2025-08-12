Rails.application.routes.draw do
  resource :registration, only: [ :new, :create ] do
    post :create_options, on: :collection
  end

  resource :session, only: [ :new, :create, :destroy ] do
    post :get_options, on: :collection
  end

  resources :webauthn_credentials, only: [ :new, :create, :destroy ] do
    post :create_options, on: :collection
  end
end
