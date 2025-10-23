# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2020-2025, by Samuel Williams.

source "https://rubygems.org"

gemspec

gem "agent-context"

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	
	gem "rubocop"
	gem "rubocop-socketry"
	
	gem "bake-test"
	gem "bake-test-external"
	
	gem "steep"
	
	gem "build-files"
end
