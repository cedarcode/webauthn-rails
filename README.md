# WebAuthn Rails

[![Gem Version](https://badge.fury.io/rb/webauthn-rails.svg)](https://badge.fury.io/rb/webauthn-rails)

**webauthn-rails** adds passkeys to your Rails app with almost no setup. It provides a generator that installs everything you need for a secure passwordless and two-factor authentication flow, built on top of the [Rails Authentication system](https://guides.rubyonrails.org/security.html). Webauthn Rails combines [Stimulus](https://stimulus.hotwired.dev/) for the frontend experience with the [WebAuthn Ruby gem](https://github.com/cedarcode/webauthn-ruby) on the server side – giving you a ready-to-use authentication system.

## Requirements

- **Ruby**: 3.2+
- **Rails**: 8.0+
- **Stimulus Rails**: This gem requires [stimulus-rails](https://github.com/hotwired/stimulus-rails) to be installed and configured in your application

### JavaScript Dependencies

The generator automatically handles JavaScript dependencies based on your setup:

- **Importmap**: Pins `@github/webauthn-json/browser-ponyfill` to your importmap
- **Node.js/Yarn/Bun**: Adds the package to your package manager

## Usage

Install the gem by running:

```bash
$ bundle add webauthn-rails --group development
```

Next, you need to run the generator:

```bash
$ bin/rails generate webauthn_authentication
```

If you haven't generated Rails authentication yet, you can pass the `--with-rails-authentication` flag in order to generate it alongside the webauthn authentication:
```bash
$ bin/rails generate webauthn_authentication --with-rails-authentication
```

This generator will:

- **Optionally** invoke the [Rails Authentication generator](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/authentication/authentication_generator.rb) if the `--with-rails-authentication` flag is passed.
- Modifies the `SessionsController` to support WebAuthn two-factor authentication.
- Create controllers for handling passwordless and two-factor authentication, as well as credential management.
- Update new session views to support passkey authentication.
- Add views for credential management and two-factor authentication.
- Update the `User` model to include association with credentials and webauthn-related logic.
- Generate database migrations for WebAuthn credentials.
- Add passkey authentication, two-factor authentication and credential management routes.
- Generate a Stimulus controller for WebAuthn interactions.
- Create the WebAuthn initializer.

### Post-Installation Configuration

After running the generator, you **must** configure the WebAuthn settings:

1. Edit `config/initializers/webauthn.rb` and set your allowed origins and Relying Party name:

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
$ bin/rails db:migrate
```

## How it Works

### User Sign-In

Users can sign in by visiting `/session/new`. The generated setup supports two ways to log in:

- Email and password – via the standard Rails Authentication flow. On top of that, if the user has enabled two-factor authentication, they will be prompted to verify with a WebAuthn credential.
- Passkey (WebAuthn) – by selecting a [passkey](https://www.w3.org/TR/webauthn-3/#discoverable-credential) linked to the user’s account.

The WebAuthn passkey sign-in flow works as follows:
1. User clicks "Sign in with Passkey", starting a WebAuthn authentication ceremony.
2. Browser shows available passkeys.
3. User selects a passkey and verifies with their [authenticator](https://www.w3.org/TR/webauthn-3/#webauthn-authenticator).
4. The server verifies the response and signs in the user.

The WebAuthn two-factor authentication flow works as follows:
1. User signs in with email and password.
2. If the user has 2FA enabled, they are asked to use a webauthn credential to complete sign-in.
3. User selects a credential and verifies with their authenticator.
4. The server verifies the response and completes sign-in.

### Adding Credentials

Signed-in users can add passkeys by visiting `/passkeys/new`, and second factor credentials by visiting `/second_factor_webauthn_credentials/new`.


### Models

#### User Model

The generator adds WebAuthn functionality to your User model:

```ruby
class User < ApplicationRecord
  has_many :webauthn_credentials, dependent: :destroy
  with_options class_name: "WebauthnCredential" do
    has_many :second_factor_webauthn_credentials, -> { second_factor }
    has_many :passkeys, -> { passkey }
  end

  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end

  def second_factor_enabled?
    webauthn_credentials.any?
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

  enum :authentication_factor, { first_factor: 0, second_factor: 1 }

  scope :passkey, -> { first_factor }
end
```

## Customization

### Views

The generator creates view templates that you can customize:

- `app/views/passkeys/new.html.erb` - Add new passkey form.
- `app/views/second_factor_webauthn_credentials/new.html.erb` - Add new second factor credential form.
- `app/views/second_factor_authentications/new.html.erb` - Two-factor authentication form.

### Stimulus Controller

The generated Stimulus controller (`webauthn_credentials_controller.js`) handles the WebAuthn JavaScript API interactions. You can extend or customize it for your specific needs.

## Contributing

Issues and pull requests are welcome on GitHub at https://github.com/cedarcode/webauthn-rails.

### Development

After checking out the repo, run:

```bash
$ bundle install
```

To run the tests:

```bash
$ bundle exec rake test
$ bundle exec rake test_dummy
```

To run the linter:

```bash
$ bundle exec rubocop
```

Before submitting a PR, make sure both tests pass and there are no linting errors.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
