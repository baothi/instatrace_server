namespace :import do
  desc "Parses all shipments data from the files"
  task :shipments => :environment do
    #Check setting
    setting = Setting.find_by_name('EnableWorldTrakIntegration')    
    if setting && setting.value == '1'      
        new_path = "/home/worldtrakftp/"   
        old_path = "/home/worldtrakftp/old/"
        
        parse_files = Dir.glob(new_path+'EDI*.txt')
        
        parse_files.each do |file|
          Parser.new(:file_name => file, :path => '',:parser_type => '', :file_type => '214')
          FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
          puts file
        end
    end   
  end

  task :milestones => :environment do   
    #Check setting
    setting = Setting.find_by_name('EnableForwardAirIntegration')
    if setting && setting.value == '1'
       forwardair_path = "/home/forwardairftp/"
       old_path = "/home/forwardairftp/old/"
       parse_files = Dir.glob(forwardair_path+'*.214')
       
       parse_files.each do |file|
          Parser.new(:file_name => file, :path => '',:parser_type => 'milestones_forwardair', :file_type => '214')
          FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
          puts "==============================Updated Forward Air Milestones: #{file}"
       end
    end

    setting = Setting.find_by_name('EnableDescartesIntegration')    
    if setting && setting.value == '1'    
       descartes_path = "/home/descartesftp/"
       old_path = "/home/descartesftp/old/"
       
       parse_files = Dir.glob(descartes_path+'*.FSA')
       
       parse_files.each do |file|
          Parser.new(:file_name => file, :path => '', :parser_type => 'milestones_descartes', :file_type => '')
          FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
          puts "==============================Updated Descartes Milestones: #{file}"
       end
    end

  end
  
  desc "Remove old shipmetns from database"
  task :remove_shipments => :environment do
    Shipment.joins(:milestones).where('milestones.action = ? AND milestones.updated_at <= ?', 'delivery', Date.today - 6.months).each{|item| item.destroy}
  end

  desc "Run all tasks at the time"
  task :run_all => [:shipments, :milestones] do
    puts '**********************All tasks was processed completely**********************'
  end

  task :getfile => :environment do 
    require 'net/ftp'
    fsr_file = File.join(Rails.root, "tmpfile","descartes", "FSR.txt")
    if File.exists?(fsr_file)
       File.delete
       puts "**********************Delete old file if existing****************"        
    end
    hawb = '341197'
    @shipment = Shipment.find_by_hawb(hawb)
    receiver_id = @shipment.mawb[0..2]
    real_mawb = @shipment.mawb[3..-1]

    iata = DESCARTES_CARRIER['carrier'][receiver_id]
   
    File.open(fsr_file,"w+") do |f|     
      f.write("QK #{iata}\n")   
      f.write(".SFOTRPA 141131\n")
      f.write("FSR\n")
      f.write("#{receiver_id}-#{real_mawb}\n")
    end

    descartes_config = COMMON['config']['ftp']['descartes']

    current =Date.today.to_time
    timestamp = Time.new.to_time.to_i.to_s

    ftp = Net::FTP::new(descartes_config["host"])  
    ftp.login(descartes_config["username"], descartes_config["password"])
    ftp.passive = true
    ftp.puttextfile(fsr_file,"FSR.txt")    
    ftp.chdir(iata)
    ftp.gettextfile("cargoimp.FSA","/home/descartesftp/cargoimp#{timestamp}.FSA")
    
    ftp.close   
    puts "***************************PUT FILE TO FTP**************"   
  
    
  end

end
