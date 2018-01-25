source 'https://rubygems.org'

# calculate the correct package names from the current ruby version
ruby_version_segments = Gem::Version.new(RUBY_VERSION.dup).segments
minor_version = "#{ruby_version_segments[0]}.#{ruby_version_segments[1]}"

gem 'puppet-blacksmith'
gem "puppet-module-posix-default-r#{minor_version}"

group :development do
  gem "puppet-module-posix-dev-r#{minor_version}"
end
