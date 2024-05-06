say "Add Webauthn Stimulus controllers"
empty_directory "app/javascript/controllers/webauthn/rails"
copy_file "#{__dir__}/app/javascript/controllers/webauthn/rails/add_credential_controller.js",
  "app/javascript/controllers/webauthn/rails/add_credential_controller.js"
copy_file "#{__dir__}/app/javascript/controllers/webauthn/rails/new_registration_controller.js",
  "app/javascript/controllers/webauthn/rails/new_registration_controller.js"
copy_file "#{__dir__}/app/javascript/controllers/webauthn/rails/new_session_controller.js",
  "app/javascript/controllers/webauthn/rails/new_session_controller.js"

say %(Appending: pin "@github/webauthn-json", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js")
append_to_file "config/importmap.rb", %(pin "@github/webauthn-json", to: "https://ga.jspm.io/npm:@github/webauthn-json@2.1.1/dist/esm/webauthn-json.js"\n)

say %(Appending: pin "webauthn-rails/credential", to: "credential.js")
append_to_file "config/importmap.rb", %(pin "webauthn-rails/credential", to: "credential.js"\n)
