Webauthn::Rails.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  config.webauthn_origin = "http://localhost:3030"
end
