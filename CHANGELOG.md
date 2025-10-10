# Changelog

## Unreleased
### Added

### Changed
- Make system tests agnostic to the user's application. [#97](https://github.com/cedarcode/webauthn-rails/pull/97) [@joaquintomas2003]

### Fixed

- Passkeys being referenced as 'Security Keys'. [#99](https://github.com/cedarcode/webauthn-rails/pull/99) [@santiagorodriguez96]

## [v0.1.1] - 2025-10-01

### Added
- Generates tests for 2FA controllers. [#88](https://github.com/cedarcode/webauthn-rails/pull/88) [@joaquintomas2003]

### Changed
- Fixed `require_no_authentication` method [#89](https://github.com/cedarcode/webauthn-rails/pull/89) [@joaquintomas2003]
- Fixed `current_authentication_user_id` method [#90](https://github.com/cedarcode/webauthn-rails/pull/90) [@joaquintomas2003]
- Refactored generated tests [#92](https://github.com/cedarcode/webauthn-rails/pull/92) [@joaquintomas2003]
- Fixed generator failing in Rails 8.1 [#94](https://github.com/cedarcode/webauthn-rails/pull/94) [@joaquintomas2003]

## [v0.1.0] - 2025-09-26

### Initial release

- Provides passkey authentication for Rails apps with minimal setup.
- Built on top of the Rails Authentication system.
- Includes support for both **first-factor** and **second-factor** authentication.

[v0.1.1]: https://github.com/cedarcode/webauthn-rails/compare/v0.1.0...v0.1.1/
[v0.1.0]: https://github.com/cedarcode/webauthn-rails/compare/v0.0.0...v0.1.0/

[@joaquintomas2003]: https://github.com/joaquintomas2003
