# Development seed data for Outpost chat
# Run with: bin/rails db:seed
# Reset and seed: bin/rails db:reset

# Create account
account = Account.create!(name: "Outpost Dev")

# Create admin user
admin = account.users.create!(
  email_address: "admin@example.com",
  password: "password",
  password_confirmation: "password",
  admin: true
)

# Create regular user
user = account.users.create!(
  email_address: "user@example.com",
  password: "password",
  password_confirmation: "password",
  admin: false
)

# Create General room
general = account.rooms.create!(name: "General")

# Add both users to General
general.memberships.create!(user: admin)
general.memberships.create!(user: user)

# Add some sample messages
general.messages.create!(user: admin, body: "Welcome to Outpost!")
general.messages.create!(user: user, body: "Thanks! This looks great.")
general.messages.create!(user: admin, body: "Let me know if you have any questions.")
general.messages.create!(user: user, body: "Will do. The retro aesthetic is really cool.")
general.messages.create!(user: admin, body: "Glad you like it! It's inspired by early computing and terminal interfaces.")

puts "=" * 50
puts "Seeded successfully!"
puts "=" * 50
puts ""
puts "Account: #{account.name}"
puts "Rooms: #{Room.count}"
puts "Users: #{User.count}"
puts "Messages: #{Message.count}"
puts ""
puts "Login credentials:"
puts "  Admin: admin@example.com / password"
puts "  User:  user@example.com / password"
puts ""
puts "=" * 50
