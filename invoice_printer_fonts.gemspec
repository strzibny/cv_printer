lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cv_printer/version'

FONTS_FILES = [
  'LICENSE.txt',
  'FONTS_LICENSE.txt',
  'assets/fonts/overpass/OFL-1.1.txt',
  'assets/fonts/overpass/Overpass-Regular.ttf',
  'assets/fonts/overpass/Overpass-Bold.ttf',
  'assets/fonts/opensans/Apache-2.0.txt',
  'assets/fonts/opensans/OpenSans-Regular.ttf',
  'assets/fonts/opensans/OpenSans-Bold.ttf',
  'assets/fonts/roboto/Apache-2.0.txt',
  'assets/fonts/roboto/Roboto-Regular.ttf',
  'assets/fonts/roboto/Roboto-Bold.ttf',
  'lib/cv_printer/fonts.rb'
]

Gem::Specification.new do |spec|
  spec.name          = 'cv_printer_fonts'
  spec.version       = CvPrinter::VERSION
  spec.authors       = ['Josef Strzibny']
  spec.email         = ['strzibny@strzibny.name']
  spec.summary       = 'Super simple resume PDF generator'
  spec.description   = 'Super simple resume PDF generator in pure Ruby (based on Prawn library).'
  spec.homepage      = 'https://github.com/strzibny/cv_printer'
  spec.licenses      = ['MIT', 'OFL 1.1', 'Apache 2.0']

  # Include only font files
  spec.files         = FONTS_FILES
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_dependency 'cv_printer', CvPrinter::VERSION

  spec.add_development_dependency 'bundler', '>= 1.7'
  spec.add_development_dependency 'rake', '>= 10.0'
end
