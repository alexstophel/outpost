# Development seed data for Outpost chat
# Run with: bin/rails db:seed
# Reset and seed: bin/rails db:reset

# Create account
account = Account.create!(name: "Outpost Dev")

# Create admin user
admin = account.users.create!(
  name: "Alex Chen",
  email_address: "alex@example.com",
  password: "password",
  password_confirmation: "password",
  admin: true
)

# Create team members
team_members = [
  { name: "Jordan Rivera", email: "jordan@example.com", admin: false },
  { name: "Sam Patel", email: "sam@example.com", admin: false },
  { name: "Taylor Kim", email: "taylor@example.com", admin: false },
  { name: "Morgan Lee", email: "morgan@example.com", admin: false },
  { name: "Casey Nguyen", email: "casey@example.com", admin: false },
  { name: "Riley Johnson", email: "riley@example.com", admin: false },
  { name: "Jamie Wilson", email: "jamie@example.com", admin: false },
  { name: "Drew Martinez", email: "drew@example.com", admin: false }
]

users = [ admin ]
team_members.each do |attrs|
  users << account.users.create!(
    name: attrs[:name],
    email_address: attrs[:email],
    password: "password",
    password_confirmation: "password",
    admin: attrs[:admin]
  )
end

alex, jordan, sam, taylor, morgan, casey, riley, jamie, drew = users

# Create public channels
channels = {
  "general" => nil,
  "random" => nil,
  "engineering" => nil,
  "design" => nil,
  "product" => nil,
  "announcements" => nil
}

channel_objects = {}
channels.each do |name, description|
  channel_objects[name] = account.rooms.create!(
    name: name,
    room_type: :channel,
    visibility: :public_room
  )
end

# Create private channels
private_channels = {
  "leadership" => nil,
  "budget" => nil,
  "hiring" => nil
}

private_channel_objects = {}
private_channels.each do |name, description|
  private_channel_objects[name] = account.rooms.create!(
    name: name,
    room_type: :channel,
    visibility: :private_room
  )
end

all_channels = channel_objects.merge(private_channel_objects)

# Add all users to general and random
all_channels["general"].memberships.create!(user: alex)
all_channels["random"].memberships.create!(user: alex)

channel_objects.each do |name, channel|
  next if name == "announcements"
  users.each { |user| channel.memberships.find_or_create_by(user: user) }
end

# Private channels - selective membership
[ private_channel_objects["leadership"], private_channel_objects["budget"] ].each do |channel|
  [ alex, jordan, sam ].each { |user| channel.memberships.find_or_create_by(user: user) }
end

private_channel_objects["hiring"].memberships.find_or_create_by(user: alex)
private_channel_objects["hiring"].memberships.find_or_create_by(user: jordan)
private_channel_objects["hiring"].memberships.find_or_create_by(user: taylor)

# Announcements - everyone
channel_objects["announcements"].memberships.find_or_create_by(user: alex)
users.each { |user| channel_objects["announcements"].memberships.find_or_create_by(user: user) }

# Create DMs between various users
dm_pairs = [
  [ alex, jordan ],
  [ alex, sam ],
  [ jordan, sam ],
  [ taylor, morgan ],
  [ casey, riley ],
  [ jamie, drew ],
  [ sam, taylor ],
  [ alex, casey ],
  [ jordan, riley ],
  [ morgan, jamie ]
]

dm_rooms = []
dm_pairs.each do |user_a, user_b|
  dm_rooms << Room.find_or_create_dm(user_a, user_b, account)
end

# Add messages to General
general = channel_objects["general"]
general.messages.create!(user: alex, body: "Hey everyone! Welcome to Outpost. Let me know if you have any questions.")
general.messages.create!(user: jordan, body: "Thanks Alex! The retro aesthetic is really cool.")
general.messages.create!(user: sam, body: "I love the terminal vibes. Reminds me of working on mainframes back in the day.")
general.messages.create!(user: taylor, body: "The pixel art icons are amazing. Who designed those?")
general.messages.create!(user: alex, body: "Thanks! I did the design myself. Inspired by old CRT monitors.")
general.messages.create!(user: morgan, body: "The color scheme is really nice. Easy on the eyes.")
general.messages.create!(user: casey, body: "Is there a dark mode?")
general.messages.create!(user: alex, body: "It's always dark mode! 😄 That's the only mode we have.")
general.messages.create!(user: riley, body: "Perfect for late night coding sessions.")
general.messages.create!(user: jamie, body: "Just joined. This looks awesome!")
general.messages.create!(user: drew, body: "The keyboard shortcuts are really well thought out.")

# Add messages to engineering
engineering = channel_objects["engineering"]
engineering.messages.create!(user: sam, body: "Anyone seen the new Rust RFC? Pretty interesting approach to memory safety.")
engineering.messages.create!(user: morgan, body: "Which one? There have been a few lately.")
engineering.messages.create!(user: sam, body: "The one about implicit resource management. Looks like it could simplify a lot of code.")
engineering.messages.create!(user: alex, body: "I read through it. The ergonomics look great but I'm worried about the learning curve.")
engineering.messages.create!(user: sam, body: "Fair point. Might need some good documentation examples.")
engineering.messages.create!(user: morgan, body: "We should probably wait until it's stable before considering it for production.")
engineering.messages.create!(user: casey, body: "Has anyone tried the new async runtime? Performance numbers look promising.")
engineering.messages.create!(user: sam, body: "Yeah I benchmarked it last week. 15% improvement on our workload.")
engineering.messages.create!(user: alex, body: "Nice! That's significant. Let's add it to the tech radar.")

# Add messages to design
design = channel_objects["design"]
design.messages.create!(user: taylor, body: "Just uploaded the new mockups for the dashboard redesign.")
design.messages.create!(user: jordan, body: "Looking at them now. The color palette is really clean.")
design.messages.create!(user: taylor, body: "Thanks! I tried to keep it consistent with the existing theme.")
design.messages.create!(user: morgan, body: "Love the new icon set. Much more readable at small sizes.")
design.messages.create!(user: taylor, body: "Good call on that. I was worried about the 16px versions.")
design.messages.create!(user: jordan, body: "The spacing feels more intentional too. Good work!")
design.messages.create!(user: alex, body: "These look great. Let's schedule a review for tomorrow?")
design.messages.create!(user: taylor, body: "Works for me. I'll prepare the presentation.")

# Add messages to product
product = channel_objects["product"]
product.messages.create!(user: jordan, body: "Q3 planning is coming up. Any feature requests?")
product.messages.create!(user: alex, body: "I'd love to see better search functionality.")
product.messages.create!(user: casey, body: "Mobile notifications are still a bit delayed on iOS.")
product.messages.create!(user: jordan, body: "Good points. I'll add those to the roadmap.")
product.messages.create!(user: riley, body: "What about keyboard shortcuts? Power users would love that.")
product.messages.create!(user: alex, body: "Already on the list! Should be in the next sprint.")
product.messages.create!(user: morgan, body: "Can we also look at improving the onboarding flow?")
product.messages.create!(user: jordan, body: "Definitely. The conversion rate from signup to first message is lower than expected.")

# Add messages to random
random = channel_objects["random"]
random.messages.create!(user: jamie, body: "Anyone watching the game tonight?")
random.messages.create!(user: drew, body: "Count me in! Let's grab some pizza.")
random.messages.create!(user: riley, body: "Can't make it tonight, but maybe Friday?")
random.messages.create!(user: jamie, body: "Friday works! I'll bring the snacks.")
random.messages.create!(user: morgan, body: "Has anyone tried that new coffee place downtown?")
random.messages.create!(user: taylor, body: "Yes! The matcha latte is incredible.")
random.messages.create!(user: sam, body: "I heard they use locally sourced beans.")
random.messages.create!(user: casey, body: "We should do a coffee run tomorrow morning.")

# Add messages to announcements
announcements = channel_objects["announcements"]
announcements.messages.create!(user: alex, body: "📢 Company all-hands this Friday at 2pm! We'll be reviewing Q2 results and discussing Q3 goals.")
announcements.messages.create!(user: alex, body: "🎉 Big thanks to the engineering team for shipping the new release ahead of schedule!")
announcements.messages.create!(user: jordan, body: "Reminder: Please submit your expense reports by end of week.")

# Add messages to leadership (private)
leadership = private_channel_objects["leadership"]
leadership.messages.create!(user: alex, body: "The board meeting went well. We're getting additional funding.")
leadership.messages.create!(user: jordan, body: "That's great news! How much?")
leadership.messages.create!(user: alex, body: "Series B, $15M. Should give us 18 months of runway.")
leadership.messages.create!(user: sam, body: "We should start hiring more aggressively now.")
leadership.messages.create!(user: alex, body: "Agreed. Let's discuss the hiring plan in our next sync.")

# Add messages to hiring (private)
hiring = private_channel_objects["hiring"]
hiring.messages.create!(user: jordan, body: "We have 3 senior engineer positions open. Resume flow is good.")
hiring.messages.create!(user: taylor, body: "Design candidate Sarah Martinez is available for a final round next week.")
hiring.messages.create!(user: jordan, body: "Perfect. I'll coordinate with Alex on scheduling.")
hiring.messages.create!(user: alex, body: "Looking forward to meeting her portfolio was impressive.")
hiring.messages.create!(user: taylor, body: "She has great experience from her previous role at a big tech company.")

# Add some DM messages
dm_rooms[0].messages.create!(user: alex, body: "Hey Jordan, do you have a minute to discuss the product roadmap?")
dm_rooms[0].messages.create!(user: jordan, body: "Sure! What's on your mind?")
dm_rooms[0].messages.create!(user: alex, body: "I think we should prioritize the mobile app refresh. User feedback has been consistent.")
dm_rooms[0].messages.create!(user: jordan, body: "Agreed. Let's move that up in the priority list.")

dm_rooms[1].messages.create!(user: alex, body: "Sam, can you review my PR when you get a chance?")
dm_rooms[1].messages.create!(user: sam, body: "On it! Should have comments by end of day.")
dm_rooms[1].messages.create!(user: alex, body: "Thanks! It's the authentication refactor.")
dm_rooms[1].messages.create!(user: sam, body: "Oh nice, I've been wanting to look at that code anyway.")

dm_rooms[3].messages.create!(user: taylor, body: "Morgan! Love the new illustrations on the landing page.")
dm_rooms[3].messages.create!(user: morgan, body: "Thanks! Took forever to get the proportions right.")
dm_rooms[3].messages.create!(user: taylor, body: "The attention to detail is amazing. Great work!")
dm_rooms[3].messages.create!(user: morgan, body: "Appreciate it! Let me know if you need anything else designed.")

dm_rooms[4].messages.create!(user: casey, body: "Riley, do you know when the next deployment is?")
dm_rooms[4].messages.create!(user: riley, body: "Scheduled for Tuesday morning. Why?")
dm_rooms[4].messages.create!(user: casey, body: "Just wanted to make sure my changes are included.")
dm_rooms[4].messages.create!(user: riley, body: "You're good. I see your PR merged yesterday.")

puts "=" * 50
puts "Seeded successfully!"
puts "=" * 50
puts ""
puts "Account: #{account.name}"
puts "Public Channels: #{Room.channels.where(visibility: 'public_room').count}"
puts "Private Channels: #{Room.channels.where(visibility: 'private_room').count}"
puts "Direct Messages: #{Room.direct_messages.count}"
puts "Users: #{User.count}"
puts "Messages: #{Message.count}"
puts ""
puts "Login credentials:"
puts "  Admin: alex@example.com / password"
puts "  Team:  jordan@example.com, sam@example.com, etc. / password"
puts ""
puts "=" * 50
