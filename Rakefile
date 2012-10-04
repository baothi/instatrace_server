# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Instatrace::Application.load_tasks

require 'resque/pool/tasks'

task "resque:setup" => :environment do
  # generic worker setup, e.g. Hoptoad for failed jobs
end
task "resque:pool:setup" do
  ActiveRecord::Base.connection.disconnect!
  Resque::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
  end
end