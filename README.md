# WebAuthn Rails

[![Gem Version](https://badge.fury.io/rb/webauthn-rails.svg)](https://badge.fury.io/rb/webauthn-rails)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](MIT-LICENSE)

A Rails engine that provides a complete WebAuthn authentication solution with passwordless login using security keys, biometrics, and other FIDO2 authenticators.

## Features

- 🔐 **Passwordless Authentication**: Complete user registration and sign-in using WebAuthn
- 🔑 **Multiple Authenticators**: Support for security keys, biometrics, and platform authenticators
- 📱 **Cross-Platform**: Works on desktop and mobile browsers with WebAuthn support
- ⚡ **Stimulus Integration**: Pre-built Stimulus controllers for seamless frontend integration
- 🛡️ **Security Best Practices**: Built on the robust [webauthn-ruby](https://github.com/cedarcode/webauthn-ruby) library
- 🎨 **Customizable Views**: Generate views that you can customize to match your application's design
- 🔧 **Rails Generator**: One-command setup with intelligent detection of existing User models

## Requirements

- **Ruby**: 3.2+
- **Rails**: 8.0+
- **Stimulus Rails**: This gem requires [stimulus-rails](https://github.com/hotwired/stimulus-rails) to be installed and configured in your application

### JavaScript Dependencies

The generator automatically handles JavaScript dependencies based on your setup:

- **Importmap**: Pins `@github/webauthn-json/browser-ponyfill` to your importmap
- **Node.js/Yarn/Bun**: Adds the package to your package manager

## Installation

Add this line to your application's Gemfile:

```ruby
gem "webauthn-rails"
```

Execute:

```bash
bundle install
```

## Setup

Run the install generator to set up WebAuthn authentication in your Rails application:

```bash
rails generate webauthn:rails:install
```

This generator will:

- Create authentication controllers (`RegistrationsController`, `SessionsController`, `WebauthnCredentialsController`)
- Add an `Authentication` concern to your `ApplicationController`
- Generate view templates for registration and sign-in
- Create or modify your `User` model with WebAuthn associations
- Generate database migrations for users and WebAuthn credentials
- Add routes for authentication endpoints
- Install and configure the Stimulus controller for WebAuthn interactions
- Set up the WebAuthn initializer

### Post-Installation Configuration

After running the generator, you **must** configure the WebAuthn settings:

1. Edit `config/initializers/webauthn.rb` and set your allowed origins:

```ruby
WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  config.allowed_origins = ["https://yourapp.com"]

  # Relying Party name for display purposes
  config.rp_name = "Your App Name"
end
```

2. Run the migrations:

```bash
rails db:migrate
```

## Usage

### User Registration

Users can register by visiting `/registration/new`. The registration flow:

1. User enters a username and nickname for their authenticator
2. JavaScript triggers the WebAuthn credential creation ceremony
3. User authenticates with their chosen method (security key, biometric, etc.)
4. New user account and credential are saved

### User Sign-In

Users can sign in by visiting `/session/new`. The sign-in flow:

1. User enters their username
2. JavaScript triggers the WebAuthn authentication ceremony
3. User authenticates with their registered authenticator
4. User is signed in and redirected

### Adding Additional Credentials

Signed-in users can add more authenticators by visiting `/webauthn_credentials/new`.

### Routes

The generator adds these routes to your application:

```ruby
resource :registration, only: [:new, :create] do
  post :create_options, on: :collection
end

resource :session, only: [:new, :create, :destroy] do
  post :get_options, on: :collection
end

resources :webauthn_credentials, only: [:new, :create, :destroy] do
  post :create_options, on: :collection
end
```

### Models

#### User Model

The generator adds WebAuthn functionality to your User model:

```ruby
class User < ApplicationRecord
  validates :username, presence: true, uniqueness: true
  has_many :webauthn_credentials, dependent: :destroy

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end
end
```

#### WebauthnCredential Model

Stores the public keys and metadata for each registered authenticator:

```ruby
class WebauthnCredential < ApplicationRecord
  belongs_to :user
  validates :external_id, :public_key, :nickname, :sign_count, presence: true
  validates :external_id, uniqueness: true
  validates :sign_count,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**32 - 1 }
end
```

## Customization

### Views

The generator creates view templates that you can customize:

- `app/views/registrations/new.html.erb` - User registration form
- `app/views/sessions/new.html.erb` - User sign-in form
- `app/views/webauthn_credentials/new.html.erb` - Add new authenticator form

### Controllers

All generated controllers can be customized as needed. The controllers handle:

- **RegistrationsController**: User registration with WebAuthn
- **SessionsController**: User authentication and sign-out
- **WebauthnCredentialsController**: Managing additional authenticators

### Stimulus Controller

The generated Stimulus controller (`webauthn_credentials_controller.js`) handles the WebAuthn JavaScript API interactions. You can extend or customize it for your specific needs.

## Contributing

Issues and pull requests are welcome on GitHub at https://github.com/cedarcode/webauthn-rails.

### Development

After checking out the repo, run:

```bash
bundle install
```

To run the tests:

```bash
bin/rails test
bin/rails test:system
```

To run the linter:

```bash
bundle exec rubocop
```

Before submitting a PR, make sure both tests pass and there are no linting errors.

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).

## Acknowledgments

- Built on top of the excellent [webauthn-ruby](https://github.com/cedarcode/webauthn-ruby) library
