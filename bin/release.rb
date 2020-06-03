#!/usr/bin/env ruby

puts "What version number do you want to release?"
print "> "
version = gets.gsub(/\n/, "")

begin
  # Change version in mix.exs file
  file = File.open(".new_mix.exs", "w")
  IO.foreach("mix.exs") do |line|
    if line.match(%r{^.*@release_version ".*".*})
      file.write(line.gsub(/\".*\"/, "\"#{version}\""))
    else
      file.write(line)
    end
  end
  file.close
  file = nil
  File.delete("mix.exs")
  File.rename(".new_mix.exs", "mix.exs")

  # Change version in README.md
  file = File.open(".README.md", "w")
  IO.foreach("README.md") do |line|
    if line.match(%r{^.*{:umbra, "~> .*"}.*})
      file.write(line.gsub(/\"~> .*\"/, "\"~> #{version}\""))
    else
      file.write(line)
    end
  end
  file.close
  file = nil
  File.delete("README.md")
  File.rename(".README.md", "README.md")

  continue = true
rescue IOError => e
  continue = false
ensure
  file.close unless file.nil?
end

continue = system "git commit -am \"Release version #{version}\"" if continue
continue = system "git tag v#{version}" if continue
continue = system "git push" if continue
continue = system "mix deps.get" if continue
continue = system "mix hex.publish" if continue

if continue
  puts "Version #{version} was successfully released!"
else
  puts "Version #{version} failed release process!"
end