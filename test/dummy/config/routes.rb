Rails.application.routes.draw do
  mount Webauthn::Rails::Engine => "/webauthn-rails"

  root "home#index"
end
