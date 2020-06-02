#!/usr/bin/env ruby

puts "What version number do you want to release?"
print "> "
version = gets.gsub(/\n/, "")

begin
  file = File.open("new_mix.exs", "w")
  IO.foreach("mix.exs") do |line|
    match = line.match(%r{^.*@release_version ".*".*})
    if match
      file.write(line.gsub(/\".*\"/, "\"#{version}\""))
    else
      file.write(line)
    end
  end
  file.close
  file = nil
  File.delete("mix.exs")
  File.rename("new_mix.exs", "mix.exs")
  continue = true
rescue IOError => e
  continue = false
ensure
  file.close unless file.nil?
end

continue = system "git commit -am \"Release version #{version}\""
continue = system "git tag v#{version}" if continue
continue = system "git push" if continue
continue = system "mix deps.get" if continue
continue = system "mix hex.publish" if continue

if continue
  puts "Version #{version} was successfully released!"
else
  puts "Version #{version} failed release process!"
end