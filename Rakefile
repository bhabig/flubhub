ENV["SINATRA_ENV"] ||= "development"


require_relative './config/environment'
require 'sinatra/activerecord/rake'

task :clean_db do
  User.destroy_all
  Order.destroy_all
  Item.destroy_all

  puts "Users: #{User.all.size}, Items: #{Item.all.size}, Orders: #{Order.all.size}"
end
