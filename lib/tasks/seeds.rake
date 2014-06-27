namespace :seeds do
  desc 'Seed ApplicationTypes'
  task :application_types => :environment do
    %w[ MobileWeb MobileNative DesktopWeb DesktopPC DesktopMac DesktopLinux].each do |name|
      ApplicationType.create(:name => name)
    end
  end
end
