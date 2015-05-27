require "pp"
require "json"

# taken from https://gist.github.com/agius/2631752 and modified slightly
def different?(a, b, bi_directional=true)

  if a.class == String and b.class == String
    a = JSON.parse(a)
    b = JSON.parse(b)
  end
  return [a.class.name, nil] if !a.nil? && b.nil?
  return [nil, b.class.name] if !b.nil? && a.nil?
  differences = {}
  a.each do |k, v|
    if k.is_a? Hash and v.nil?
      # Special case -  we appear to ahve some data as:
      # [ { { ... } } ]
      different?(v, b)
      # TODO - come back to this
    else
      if !v.nil? && b[k].nil?
        differences[k] = [v, nil]
        next
      elsif !b[k].nil? && v.nil?
        differences[k] = [nil, b[k]]
        next
      end

      if v.is_a?(Hash)
        unless b[k].is_a?(Hash)
          differences[k] = "Different types"
          next
        end
        diff = different?(a[k], b[k])
        differences[k] = diff if !diff.nil? && diff.count > 0

      elsif v.is_a?(Array)
        unless b[k].is_a?(Array)
          differences[k] = "Different types"
          next
        end

        c = 0
        diff = v.map do |n|
          if n.is_a?(Hash)
            diffs = different?(n, b[k][c])
            c += 1
            ["Differences: ", diffs] unless diffs.nil?
          else
            c += 1
            [n , b[c]] unless b[c] == n
          end
        end.compact

        differences[k] = diff if diff.count > 0

      else
        differences[k] = [v, b[k]] unless v == b[k]

      end
    end
  end

  return differences if !differences.nil? && differences.count > 0
end

pre_migration = Dir.glob("testdata/pre-migration/**/*").reject {|f|  f !~ /\.json$/ }.map { |f| f.split("/", 3)[2]  }.sort
post_migration = Dir.glob("testdata/post-migration/**/*").reject {|f| f !~ /\.json$/ }.map{ |f| f.split("/", 3)[2]  }.sort

# Simple case now - files in both
missing_in_post = []
missing_in_pre = []
differences = []
matches = []
pre_migration.each do |file|
  unless File.exists?("testdata/post-migration/#{file}")
    missing_in_post << file
    next
  end
  d = different?(File.read("testdata/pre-migration/#{file}"), File.read("testdata/post-migration/#{file}"))
  if d.nil?
    matches << file
  else
    differences << { "file" => file, "delta" => d }
  end
end

post_migration.each do |file|
  unless File.exists?("testdata/pre-migration/#{file}")
    missing_in_pre << file
    next
  end
end
pp differences
#puts missing_in_post.inspect
#puts missing_in_pre.inspect
