# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'geojson2image/version'

Gem::Specification.new do |spec|
  spec.name          = "geojson2image"
  spec.version       = Geojson2image::VERSION
  spec.authors       = ["Bryce Johnston"]
  spec.email         = ["johnstonbrc@gmail.com"]

  spec.summary       = %q{Ruby library for generating images from GeoJSON}
  spec.description   = %q{Ruby library for generating images from GeoJSON}
  spec.homepage      = "https://github.com/brycejohnston/geojson2image"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "oj", "~> 2.18"
  spec.add_dependency "chunky_png", "~> 1.3.8"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
