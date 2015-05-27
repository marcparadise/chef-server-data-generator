require 'securerandom'
require 'yaml'

begin
  @create_parms = YAML.load_file("setup.yml")
rescue
  @create_parms = YAML.load_file("setup.yml.example")
end

@time_identifier = Time.now.to_i
@orgs = {}
@usernames = []
num_users = @create_parms["users"]["count"]
num_orgs = @create_parms["orgs"]["count"]
users_per_org = @create_parms["orgs"]["per_org"]["users"]
admins_per_org = @create_parms["orgs"]["per_org"]["admins"]
clients_per_org = @create_parms["orgs"]["per_org"]["clients"]
groups_per_org =  @create_parms["orgs"]["per_org"]["groups"]

num_users.times do |x|
  # Not impossible that we'll see periodic duplicates here,
  # just rather unlikely.
  create_user("user-#{@time_identifier}-#{SecureRandom.hex(4)}")
end

num_orgs.times do
  orgname = "org-#{@time_identifier}-#{SecureRandom.hex(4)}"
  # more-or-less randomly pick our org users from the pool of all users
  org_users = random_elements(users_per_org, users_per_org, @usernames)
  org_admins = random_elements(admins_per_org, admins_per_org, org_users)
  create_org(orgname, org_users, org_admins)
  clients_per_org.times { create_org_client(orgname, false) }
  org_clients = @orgs[orgname]["clients"]
  # Creates randomly named group with random membership
  groups_per_org.times { create_and_populate_org_group(orgname, org_users, org_clients ) }
  org_groups =@orgs[orgname]["groups"].keys.reject{ |k| k == "admins" || k == "users" }

  # Just split groups in half, take the first group in each half, and add the remaining
  # groups in the half to it.   Avoids having to track circular dependencies if we do
  # it by random assignment.
  org_groups.each_slice(groups_per_org / 2) do |member_groups|
    # don't  bother if we don't have enough groups to care about.
    next if member_groups.length < 2
    owning_group = member_groups.shift
    add_to_group(orgname, owning_group, { :groups => member_groups} )
  end
end

all = { "orgs" => @orgs, "users" => @usernames }

# this is available as input for other steps and components.
File.open("created-orgs-and-users.yml", "w") do |f|
  YAML.dump(all, f)
end

##################################################################################
BEGIN {

  def create_user(name)
    puts "...creating user #{name}"
    user_key = ".chef/#{name}.pem"
    user = api.post("users",  { "display_name" => name, "email" => "#{name}@#testing.com", "username"=> name, "password" => "password"})
    File.open(user_key, "w") { |f| f.write(user['private_key']) }
    @usernames << name
  end

  def associate_user(orgname, username)
    puts "...associating #{username} with #{orgname}"
    # old style: before 12 we can't directly associate a user with an org.
    response = api.post("organizations/#{orgname}/association_requests", { "user" => username } )
    case response["uri"]
    when /.*\/(.*)$/
      api.put("users/#{username}/association_requests/#{$1}", { "response" => "accept" } )
    end
  end

  def add_to_group(orgname, groupname, who)
    who[:users] = [] if who[:users].nil?
    who[:clients] = [] if who[:clients].nil?
    who[:groups] = [] if who[:groups].nil?
    puts "...adding #{who.inspect} to #{orgname}/groups/#{groupname}"
    g = api.get("organizations/#{orgname}/groups/#{groupname}")
    g2 = g.dup
    g2["actors"] = {}
    g2["actors"]["users"] = g["users"] + who[:users]
    g2["actors"]["groups"] = g["groups"] + who[:groups]
    g2["actors"]["clients"] = g["clients"] + who[:clients]

    api.put("organizations/#{orgname}/groups/#{groupname}", g2)
    @orgs[orgname]["groups"][groupname] = {} # we're going to overwrite it with what the server just told us anyway...
    @orgs[orgname]["groups"][groupname][:users] = g2["actors"]["users"]
    @orgs[orgname]["groups"][groupname][:clients] = g2["actors"]["clients"]
    @orgs[orgname]["groups"][groupname][:groups] = g2["actors"]["groups"]
  end

  def create_org_client(orgname, validator)
    client_name = "#{orgname}-client-#{SecureRandom.hex(4)}"
    result = api.post("organizations/#{orgname}/clients", { "clientname" => client_name, "validator" => validator, "private_key" => true })

    key_file = ".chef/#{client_name}.pem"
    File.open(key_file, "w") { |f| f.write(result['private_key']) }
    @orgs[orgname]["clients"] << client_name

  end

  def create_and_populate_org_group(orgname,orgusers,orgclients)
    group_name = "#{orgname}-group-#{SecureRandom.hex(4)}"
    memberusers = random_elements(1, orgusers.length, orgusers)
    memberclients = random_elements(1, orgclients.length, orgclients)
    puts  "... creating group #{group_name}"
    # Old style - before 12 we could not add members at time of defining group
    api.post("organizations/#{orgname}/groups", {"groupname" => group_name})
    add_to_group(orgname, group_name, {:users => memberusers, :clients => memberclients})
  end

  def create_org(name, users, admins)
    puts "...creating org #{name}"
    org = api.post("organizations", { "full_name" => "#{name}", "name" => "#{name}" })
    validator_key = ".chef/#{name}-validator.pem"
    File.open(validator_key, "w") do |f|
      f.write(org['private_key'])
    end
    users.each do |username|
      associate_user(name, username)
    end
    @orgs[name] =  { "groups" => { "admins" => {}, "users" => {}},
                     "clients" => ["#{name}-validator"] }
    add_to_group(name, "admins", {:users => admins} )

  end
  def random_elements(min, max, ary)
    # Trusting you to pass in valid min/max here...
    count = rand(max - min) + min
    ary.dup.shuffle[0..count-1]
  end
}
