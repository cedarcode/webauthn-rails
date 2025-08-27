require "bundler/setup"
require 'rake/testtask'

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/tmp/**/*_test.rb').exclude('test/dummy/**/*_test.rb')
end

Rake::TestTask.new(:test_dummy) do |t|
  t.libs << 'test/dummy/lib'
  t.libs << 'test/dummy/test'
  t.test_files = FileList['test/dummy/**/*_test.rb']
end
