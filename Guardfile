# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 1, :all_after_pass => false, :all_on_start => false, :cli => "--color" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # Rails example
  watch(%r{^app/(.+)\.rb$})                           { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                 { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
  watch('config/routes.rb')                           { "spec/routing" }
  watch('app/controllers/application_controller.rb')  { "spec/controllers" }
  # Capybara request specs
  watch(%r{^app/views/(.+)/.*\.(erb|haml)$})          { |m| "spec/requests/#{m[1]}_spec.rb" }
end


guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end

# guard :test, :all_on_start => false, :all_after_pass => false, :test_paths => ['test/unit', 'test/functional'] do
#   watch(%r{^lib/(.+)\.rb$})     { |m| "test/#{m[1]}_test.rb" }
#   watch(%r{^test/.+_test\.rb$})
#   watch('test/test_helper.rb')  { "test" }
#
#   # Rails example
#   watch(%r{^app/models/(.+)\.rb$})                   { |m| "test/unit/#{m[1]}_test.rb" }
#   watch(%r{^app/controllers/(.+)\.rb$})              { |m| "test/functional/#{m[1]}_test.rb" }
#   watch(%r{^app/views/.+\.rb$})                      { "test/integration" }
#   watch('app/controllers/application_controller.rb') { ["test/functional", "test/integration"] }
# end