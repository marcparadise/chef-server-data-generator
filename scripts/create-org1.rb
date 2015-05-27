require 'securerandom'
require 'yaml'

@time_identifier = Time.now.to_i
@orgs = {}

@users = []

begin
  @create_parms = YAML.load_file("setup.yml")
rescue
  @create_parms = YAML.load_file("setup.yml.example")
end

puts "Doing the thing:"

num_users = @create_parms["users"]["count"]
num_orgs = @create_parms["orgs"]["count"]
users_per_org = @create_parms["orgs"]["per_org"]["users"]
admins_per_org = @create_parms["orgs"]["per_org"]["admins"]
clients_per_org = @create_parms["orgs"]["per_org"]["clients"]


num_users.times do |x|
  # Not impossible that we'll see periodic duplicates here,
  # just rather unlikely.
  create_user("user-#{@time_identifier}-#{SecureRandom.hex(4)}")
end

num_orgs.times do
  org_users = []
  orgname = "org-#{@time_identifier}-#{SecureRandom.hex(4)}"
  # more-or-less randomly pick our org users from the pool of all users
  org_users = (0..num_users-1).to_a.shuffle[0..users_per_org-1]
  u = org_users.map { |x| @users[x]["name"] }
  # more-or-less randomly pick our admins from our pool of org users.
  org_admins = (0..users_per_org-1).to_a.shuffle[0..admins_per_org-1]
  a = org_admins.map { |x| u[x] }
  create_org(orgname, u, a)
end

users_map = {}
@users.each do
  @users
end
all = { "orgs" => @orgs, "users" => @users }

# this is available as input for other steps and components.
File.open("created-orgs-and-users.yml", "w") do |f|
  YAML.dump(all, f)
end

BEGIN {
  def create_user(name)
    puts "...creating user #{name}"
    user_key = ".chef/#{name}.pem"
    user = api.post("users",  { "display_name" => name, "email" => "#{name}@#testing.com", "username"=> name, "password" => "password"})
    File.open(user_key, "w") { |f| f.write(user['private_key']) }
    @users << { "name" => name, "key_file" => user_key }
  end
  def associate_user(orgname, username)
    puts "...associating #{username} with #{orgname}"
    response = api.post("organizations/#{orgname}/association_requests", { "user" => username } )
    case response["uri"]
    when /.*\/(.*)$/
      api.put("users/#{username}/association_requests/#{$1}", { "response" => "accept" } )
    end
  end
  def add_to_group(orgname, groupname, usernames)
    puts "...adding #{usernames.inspect} to #{orgname}/groups/#{groupname}"
    g = api.get("organizations/#{orgname}/groups/#{groupname}")
    g2 = g.dup
    g2["actors"] = {}
    g2["actors"]["users"] = g["users"] + usernames
    g2["actors"]["groups"] = g["groups"]
    g2["actors"]["clients"] = g["clients"]
    api.put("organizations/#{orgname}/groups/#{groupname}", g2)
  end
  def create_org(name, users, admins)
    puts "...creating org #{name}"
    validator_key = ".chef/#{name}-validator.pem"
    org = api.post("organizations", { "full_name" => "#{name}", "name" => "#{name}" })
    File.open(validator_key, "w") do |f|
      f.write(org['private_key'])
    end
    users.each do |username|
      associate_user(name, username)
    end
    add_to_group(name, "admins", admins)

    @orgs[name] =  { "validator" => { "name" => "#{name}-validator", "key_file" => validator_key},
                     "groups" => { "users" => users, "admins" => admins } }

  end
}
