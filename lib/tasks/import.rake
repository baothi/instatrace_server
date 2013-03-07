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
          begin
              Parser.new(:file_name => file, :path => '',:parser_type => 'milestones_forwardair', :file_type => '214')
              FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
              puts "==============================Updated Forward Air Milestones: #{file}"
          rescue Exception => e
              message = e.message
              puts "==============================Updated Forward Air Milestones: #{file} , error: #{message}"
              next
          end
       end
    end
    setting = Setting.find_by_name('EnableDescartesIntegration')    
    if setting && setting.value == '1'    
       descartes_path = "/home/descartesftp/"
       old_path = "/home/descartesftp/old/"
       
       parse_files = Dir.glob(descartes_path+'*.FSA')
       parse_files.each do |file|
          begin
              Parser.new(:file_name => file, :path => '', :parser_type => 'milestones_descartes', :file_type => '')
              FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
              puts "==============================Updated Descartes Milestones: #{file}"
          rescue Exception => e
              message = e.message
              puts "==============================Updated Descartes Milestones: #{file} , error: #{message}"
              next
          end
       end
    end
  end
  
  desc "Remove old shipmetns from database"
  task :remove_shipments => :environment do
    Shipment.joins(:milestones).where('milestones.action = ? AND milestones.updated_at <= ?', 'delivery', Date.today - 6.months).each{|item| item.destroy}
  end

  desc "Run all tasks at the time"
  task :run_all => [:shipments, :milestones, :descartes_get_response] do
    puts '**********************All tasks was processed completely**********************'
  end
  
  # This task will get response FSA from Descartes server per each 20 minutes
  task :descartes_get_response => :environment do
    puts "**********************RUN TASK descartes_get_response**********************"
    require 'net/ftp'
    date = Date.today.to_s("YYYY-MM-DD")
    puts "Date : #{date}"
    
    list_carrier = DESCARTES_CARRIER['carrier']
    descartes_config = COMMON['config']['ftp']['descartes']
    
    # ftp = Net::FTP::new(descartes_config["host"])
    
    # if ftp.login(descartes_config["username"], descartes_config["password"])
        # ftp.passive = true
        begin_date = 3.days.ago.beginning_of_day.utc #Date.today.beginning_of_day.utc
        #end_date = Date.today.end_of_day.utc
        #Get shipments which were created/updated mawb on today ready to get response FSA from Descartes
        condition = "mawb is not null and mawb <> '' and (created_at >= ? or updated_at >= ?)"
        @shipments_updated_today = Shipment.where(condition,begin_date,begin_date)
        puts "CONDITION begin_date:#{begin_date}, total:#{@shipments_updated_today.count}"
        index_count = 0
        # Loop for each shipments were updated
        @shipments_updated_today.each do |item|
             index_count += 1
             fsr_timestamp = Time.now
             timestamp = Time.new.to_time.to_i.to_s
             #Get shipment detail
             @shipment = item
             puts "--------------------STAR #{index_count}--------------------"
             puts "RUN TIME: #{fsr_timestamp}"
             puts "FOR SHIPMENT id:#{@shipment.id}, hawb:#{@shipment.hawb}, mawb:#{@shipment.mawb}, created_at:#{@shipment.created_at}, updated_at:#{@shipment.updated_at} "
             receiver_id = @shipment.mawb[0..2]
             real_mawb = @shipment.mawb[3..-1]
             iata = DESCARTES_CARRIER['carrier'][receiver_id]
             
             # MAWB code must be 11 characters 
             # 3 characters is air carrier code which is mapped with IATA code in file descartes.yml
             # 8 next characters for real MAWB
             if @shipment.mawb.length != 11 || iata.nil? 
               puts "MAWB is blank"
             else
                 ftp = Net::FTP::new(descartes_config["host"])
                 ###################################################################################
                 #begin for if check for FTP
                 ###################################################################################
                 if ftp.login(descartes_config["username"], descartes_config["password"])
                    ftp.passive = true
                    ###################################################################################
                    #Send FSR to get next status
                    ###################################################################################
                    begin
                        fsr_file = File.join(Rails.root, "tmpfile","descartes", "FSR_TASK.txt")
                        if File.exists?(fsr_file)
                            File.delete
                        end
                        # fsr_timestamp = Time.now
                        day = fsr_timestamp.day < 10 ? '0' + fsr_timestamp.day.to_s : fsr_timestamp.day.to_s
                        hour = fsr_timestamp.hour < 10 ? '0' + fsr_timestamp.hour.to_s : fsr_timestamp.hour.to_s
                        min = fsr_timestamp.min < 10 ? '0' + fsr_timestamp.min.to_s : fsr_timestamp.min.to_s
                        
                        File.open(fsr_file,"w+") do |f|
                            f.write("QK #{iata}\n")
                            f.write(".SFOTRPA #{day}#{hour}#{min}\n")
                            f.write("FSR\n")
                            f.write("#{receiver_id}-#{real_mawb}\n")
                        end
                        
                        #Send FSR
                        ftp.puttextfile(fsr_file,"FSR#{fsr_timestamp}.txt")
                        
                        puts "SEND FSR SUCCESS"
                    rescue Exception => e
                        puts "SEND FSR ERROR (error message from Descartes) ==> #{e.message}"
                    end
                    ###################################################################################
                    #End send FSR file to get next status
                    ###################################################################################
                    
                    ###################################################################################
                    #Start begin get response FSA file
                    ###################################################################################
                    begin
                        # timestamp = Time.new.to_time.to_i.to_s
                        file_path = "/home/descartesftp/cargoimp#{timestamp}_#{@shipment.hawb}.FSA"
                        # Go to root
                        ftp.chdir('/')
                        ftp.chdir(iata).nil?
                        ftp.gettextfile("cargoimp.FSA",file_path)
                        
                        # Open this file to get receiver_id and real MAWB
                        if File.exists?(file_path)
                            data_array = File.read(file_path).split("\n")
                            # Line 4 in file should be: 006-97844342SFOPTY/T1L39.7
                            not_need_check_status = ["OSI/NO RECORD FOUND", "OSI/NO RECORD", "OSI/NO STATUS AVAILABLE", "OSI/NO AIRWAYBILL MATCH FOUND"]
                            
                            if data_array.count > 4 && ! not_need_check_status.include?(data_array[4])
                                receiver_id_real_mawb = data_array[3][0..11]
                                # Compare response request content match with our request or not
                                # If not, delete file FSA
                                if receiver_id_real_mawb == receiver_id + "-" + real_mawb
                                    puts "GET FSA FILE SUCCESS : #{file_path}"
                                else
                                    #Check valid for mawb, if this mawb is not exist in shipments table, need to delete this FSA file
                                    mawb_valid_in_db = receiver_id_real_mawb.gsub("-","")
                                    check_day = 3.months.ago.beginning_of_day.utc
                                    check_mawb_in_db = Shipment.where("mawb = ? and (created_at >= ? or updated_at >= ?)",mawb_valid_in_db,check_day,check_day)
                                    
                                    if check_mawb_in_db.blank?
                                        #Delete the file FSA
                                        FileUtils.rm(file_path)
                                    else
                                        exist_hawb = check_mawb_in_db.first.hawb
                                        puts "KEEP FOR EXIST HAWB: #{exist_hawb}, File FSA: #{file_path}"
                                    end
                                end
                            else
                                #Delete the file FSA
                                FileUtils.rm(file_path)
                                puts "DELETE FILE: content data #{data_array.inspect}"
                            end
                        else
                            puts "GET FSA FILE UNSUCCESS"
                        end
                    rescue Exception => e
                        # Remove response file empty
                        FileUtils.rm(file_path) if File.exists?(file_path)
                        #Continue loop other milestone
                        puts "GET RESPONSE FSA ERROR (error message from Descartes) ==> #{e.message}"
                        #next
                    end
                    ###################################################################################
                    #End begin get response FSA file
                    ###################################################################################
                 end
                 ###################################################################################
                 #End for if check for FTP
                 ###################################################################################
                 ftp.close
             end
             #End check valid MAWB code
             puts "--------------------END--------------------"
        end
        #End loop milestone
    # end
    # #Close FTP
    # ftp.close
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
