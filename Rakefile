require 'bundler'
Bundler::GemHelper.install_tasks(name: 'cv_printer')

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'cv_printer'

require 'rake/testtask'
Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.verbose = true
end
