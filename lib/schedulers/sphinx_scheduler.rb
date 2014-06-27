require 'rubygems'
require 'daemons'  
require 'rufus/scheduler'
require 'optparse'


options = {}
OptionParser.new do |opts|
  opts.on("-e", "--environment ENV", String, "Environment running") do |env|
    options[:environment] = env
  end
  opts.on("-p", "--process_name NAME", String, "Proccess name") do |name|
    options[:proccess_name] = name
  end
end.parse!

ENV['RAILS_ENV'] = options[:environment] || 'development'
daemon_name = options[:proccess_name] || "sphinx_scheduler_deamon"
time_to_shedule ||= "10h"

APP_DIR = File.join(File.dirname(File.expand_path(__FILE__)), '../../')

#def notification
#  begin
#    puts "notification started #{Time.now.to_s}"
#    Game.new_game_notification(Game.todays.all, true)
#    puts "notification stoped #{Time.now.to_s}"
#  rescue => e
#    puts "Notification Stoped with error #{e.inspect} #{Time.now.to_s} #{e.inspect}"
#  end
#end

Daemons.run_proc(  
 daemon_name,   
 :dir_mode => :normal,   
 :dir => File.join(APP_DIR, 'log'),  
 :multiple => false,
 :backtrace => true,  
 :monitor => false,  
 :log_output => true  
) do  
   
  begin  
    Dir.chdir(APP_DIR)  
    require File.join('config', 'environment')
    `rake thinking_sphinx:index RAILS_ENV=production`
    scheduler = Rufus::Scheduler.new
    scheduler.start
    puts "Scheduler sphinx started #{Time.now.to_s}"
    scheduler.schedule_every time_to_shedule do
      puts "sphinx index started #{Time.now.to_s}"
      `rake thinking_sphinx:index RAILS_ENV=production`
      puts "sphinx index finished #{Time.now.to_s}"
    end
    scheduler.join
  rescue => e  
    puts "Scheduler sphinx Stoped with error #{e.inspect} #{Time.now.to_s}"
    exit  
  end  
  
end  
