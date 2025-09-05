require 'bcrypt'

User.create!(
  email_address: "test@example.com",
  password: "password123"
)
