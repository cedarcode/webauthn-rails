Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  resource :webauthn_session, only: [ :create, :destroy ] do
    post :get_options, on: :collection
  end

  resources :webauthn_credentials, only: [ :new, :create, :destroy ] do
    post :create_options, on: :collection
  end

  root "home#index"
end
