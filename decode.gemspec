# frozen_string_literal: true

require_relative "lib/decode/version"

Gem::Specification.new do |spec|
	spec.name = "decode"
	spec.version = Decode::VERSION
	
	spec.summary = "Code analysis for documentation generation."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/decode"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/decode/",
		"funding_uri" => "https://github.com/sponsors/socketry/",
		"source_code_uri" => "https://github.com/socketry/decode.git",
	}
	
	spec.files = Dir.glob(["{bake,context,lib,sig}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "prism"
	spec.add_dependency "rbs"
end
