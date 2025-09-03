WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  # config.allowed_origins = [ "https://auth.example.com" ]

  # Relying Party name for display purposes
  # config.rp_name = "Example Inc."
end
