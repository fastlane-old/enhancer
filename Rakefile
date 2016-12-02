# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

# Create a new DB backup, and import it to the local Postgres DB
task :db do
  app = ENV["HEROKU_APP"] || "fastlane-enhancer"
  db_name = ENV["DB_NAME"] || "enhancer"
  user = ENV["USER"]

  puts "This script is going to drop your local database #{db_name} and fetch the database from heroku #{app}. Quit now if that doesn't sound good, or press any key to continue"
  STDIN.gets

  Bundler.with_clean_env do
    sh "heroku pg:backups capture --app #{app}"
    sh "curl -o latest.dump `heroku pg:backups public-url --app #{app}`"
    sh "dropdb #{db_name} || true"
    sh "createdb #{db_name}"
    sh "pg_restore --verbose --clean --no-acl --no-owner -h localhost -U #{user} -d #{db_name} latest.dump"
  end
end
