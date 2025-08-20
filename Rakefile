require "bundler/setup"
require 'rake/testtask'

load "rails/tasks/statistics.rake"

require "bundler/gem_tasks"

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude('test/tmp/**/*_test.rb').exclude('test/dummy/**/*_test.rb')
  t.verbose = true
  t.warning = false
end

Rake::TestTask.new(:test_dummy) do |t|
  t.libs << 'test/dummy/lib'
  t.libs << 'test/dummy/test'
  t.test_files = FileList['test/dummy/**/*_test.rb']
  t.verbose = true
  t.warning = false
end
