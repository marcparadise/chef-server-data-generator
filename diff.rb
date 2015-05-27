require "pp"
require "json"
require "easy_diff"
require "yaml"


pre_migration = Dir.glob("testdata/pre-migration/**/*").reject {|f|  f !~ /\.json$/ }.map { |f| f.split("/", 3)[2]  }.sort
post_migration = Dir.glob("testdata/post-migration/**/*").reject {|f| f !~ /\.json$/ }.map{ |f| f.split("/", 3)[2]  }.sort

# Simple case now - files in both
missing_in_post = []
missing_in_pre = []
differences = []
matches = []
errors = []
key_replacements = []
key_newline_diff = []
pre_migration.each do |file|
  begin
    unless File.exists?("testdata/post-migration/#{file}")
      missing_in_post << file
      next
    end
    pre = JSON.parse(File.read("testdata/pre-migration/#{file}"))
    post = JSON.parse(File.read("testdata/post-migration/#{file}"))
    if pre.is_a? Array and post.is_a? Array
      pre = { :wrapper => pre }
      post = { :wrapper => post }
    end
    removed, added = EasyDiff::Core.easy_diff pre, post
    if removed.has_key?("certificate")  and added.has_key?("public_key") and added.keys.length == removed.keys.length
      key_replacements << file
      removed.delete "certificate"
      added.delete "public_key"
    elsif removed.has_key?("public_key") and added.has_key? "public_key" and added["public_key"].strip == removed["public_key"].strip
      key_newline_diff << file
      removed.delete "public_key"
      added.delete "public_key"
    end
    if removed.keys.length == 0 and added.keys.length == 0
      matches << file
    else
      differences << { "object" => file, "added"=> added, "removed" => removed }
    end
  rescue => e
    errors << { "object" => file, "error" => e.message }
  end

end

post_migration.each do |file|
  unless File.exists?("testdata/pre-migration/#{file}")
    missing_in_pre << file
    next
  end
end

puts YAML.dump( { "Errors" => errors,
                  "Differences Found" => differences,
                  "Not Present Post-Migration" => missing_in_post,
                  "New Post-Migration" =>  missing_in_pre,
                  "Certs Replaced With Keys" => key_replacements,
                  "Key Newline Mismatch" => key_newline_diff })
