Rails.application.routes.draw do
  resource :webauthn_session, only: [ :create, :destroy ] do
    post :get_options, on: :collection
  end

  resources :passkeys, only: [ :new, :create, :destroy ] do
    post :create_options, on: :collection
  end

  resources :second_factor_webauthn_credentials, only: [ :new, :create, :destroy ] do
    post :create_options, on: :collection
  end

  resource :second_factor_authentication, controller: "second_factor_authentication", only: [ :new, :create ] do
    post :get_options, on: :collection
  end

  resource :session
  resources :passwords, param: :token

  root "home#index"
end
