guard 'rspec', :all_after_pass => false, :all_on_start => false do
  watch(%r{^spec/(.+)_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})
  watch('spec/spec_helper.rb')                        { "spec" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
end

