require 'securerandom'

def create_node(name, base_url)
  puts "...creating node #{name}"
  attributes = {}
  rand(10 - 0).times do |x|
    attributes["key-#{x}"] = "value-#{x}"
  end
  api.post("#{base_url}/nodes", {"name" => name, "chef_environment" => "_default", "normal" => attributes, "automatic" => {}, "override" => {}, "default" => {}, "run_list" => []})
end

def create_role(name, base_url)
  puts "...creating role #{name}"
  run_list = ["recipe[unicorn]", "recipe[apache2]"]
  api.post("#{base_url}/roles",  { "name" => name, "default_attributes" => {},  "description" => "A role",  "override_attributes" => {}, "run_list" => run_list})
end


def create_data_bag(name, items_per_bag, keys_per_bag, time_identifier, base_url)
  puts "...creating data bag #{name}"
  items_per_bag.times do |x|
    "data-bag-item-#{@time_identifier}-#{SecureRandom.hex(4)}"
  end
  api.post("#{base_url}/data",  { "name" => name })

  items_per_bag.times do |y|
    item_name = "data-bag-item-#{time_identifier}-#{SecureRandom.hex(4)}"
    payload = {"id" => item_name}

    keys_per_bag.times do |z|
      payload["key#{z}"] = "value#{z}"
    end
    api.post("#{base_url}/data/#{name}", payload)
  end
end
