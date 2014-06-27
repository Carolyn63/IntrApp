task :cron => :environment do
  puts "Pulling new requests for Rails......"
  puts "**************************"
  puts "Deleting Users............"
  User.delete_orphans
  puts "Deactivate services......."
  Companification.destroy_unpaid_application
  puts "**************************"
  
  puts "done....."
  
  
end