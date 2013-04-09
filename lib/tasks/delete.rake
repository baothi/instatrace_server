namespace :del do
  desc "Delete all files are created more than one month"
  
  task :remove_old_files => :environment do   
    current = Time.now
    
    #Check setting
    setting = Setting.find_by_name('EnableForwardAirIntegration')
    if setting && setting.value == '1'
       old_path = "/home/forwardairftp/old/"
       old_files = Dir.glob(old_path +'*.214')
       
       old_files.each do |file|
          created_time = File.ctime(file)
          numdays = (current - created_time).to_i
          if(numdays > 30)
                File.delete(file)
                puts "==============================Delete Forward Air Old file: #{file}"
          end              
        end
    end
    
    setting = Setting.find_by_name('EnableTowneAirIntegration')
    if setting && setting.value == '1'
       old_path = "/home/towneairftp/old/"
       old_files = Dir.glob(old_path +'*.214')
       
       old_files.each do |file|
          created_time = File.ctime(file)
          numdays = (current - created_time).to_i
          if(numdays > 30)
                File.delete(file)
                puts "==============================Delete Towne Air Old file: #{file}"
          end              
        end
    end
    
    setting = Setting.find_by_name('EnableDescartesIntegration')
    if setting && setting.value == '1'
       old_path = "/home/descartesftp/old/"
       old_files = Dir.glob(old_path +'*.FSA')
       
       old_files.each do |file|
          created_time = File.ctime(file)
          numdays = (current - created_time).to_i
          if(numdays > 30)
                File.delete(file)
                puts "==============================Delete Descartes Old file: #{file}"
          end              
        end
      end
    
    setting = Setting.find_by_name('EnableWorldTrakIntegration')
    if setting && setting.value == '1'
       old_path = "/home/worldtrakftp/old/"
       old_files = Dir.glob(old_path+'EDI*.txt')
       
       old_files.each do |file|
          created_time = File.ctime(file)
          numdays = (current - created_time).to_i
          if(numdays > 30)
                File.delete(file)
                puts "==============================Delete Worldtrak Old file: #{file}"
          end              
        end
      end     
    
    end
end
