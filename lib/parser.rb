class Parser
  class EDITransaction
    attr_accessor :data, :actions, :ship
    
    def initialize(data, parser_type, file_type)
      isa = nil
      fsa = nil
      @data = data
      if file_type && file_type == '214'
          raise 'File has wrong format' unless self.isa?
      end
      if parser_type && ( parser_type == 'milestones_forwardair' || parser_type == 'milestones_towneair')
        plain = data.gsub(/\r/, '').split('~').map{|line| line.split('*')}
        
      elsif parser_type && parser_type == 'milestones_descartes'        
        #Descartes is not use 214 standard 
        fsa = data.gsub(/\n/, '~').split('~') #TODO              
        plain = data.gsub(/\n/, '~').split('~').map{|line| line.split('/')}
      else        
        plain = data.gsub(/~/, '').gsub(/\n/, '~').gsub(/\r/, '').split('~').map{|line| line.split('*')}
      end

      if file_type && file_type == '214'
         isa = plain.find{|d| d.first.eql? "ISA"}
         self.ship = Time.parse("20" << isa[9] << isa[10])
         until plain.size.zero?
           plain = plain.drop_while{ |el| !el.first.eql?("ST") }
           plain.shift
           (self.actions||=[]) << plain.take_while{ |el| !el.first.eql?("ST") }
         end
      else        
          until plain.size.zero?
            plain = plain.drop_while{ |el| !el.first.eql?("FSA") }
            plain.shift            
            (self.actions||=[]) << plain.take_while{ |el| !el.first.eql?("FSA") }            
         end 
      end
      
    end
    
    def isa?
      data =~ /isa\*\d{2}\*/i
    end
    
  end

  attr_accessor :data, :spec
  attr_reader :errors
  
  def initialize(*args)
    @errors = []
    options = Hash[*args]
    unless options[:file_name].nil?
      path = options[:path] || default_files_path
      files_path = File.join(path, options[:file_name])      
    end
    self.data = EDITransaction.new(options[:data] || IO.read(files_path), options[:parser_type], options[:file_type])
    raise 'Data is not defined.' if self.data.nil?
    forwardair_status = nil
    towneair_status = nil
    descartes_status = nil
    
    if options[:parser_type] && options[:parser_type] == 'milestones_forwardair'
      forwardair_status = YAML::load(File.open(File.join(Rails.root, "config", "forwardair.yml")))
      user = User.find_by_login('ForwardAir')
      driver_id = user.id if user      
      self.data.actions.each {|a| create_milestones_forwardair(a, driver_id, forwardair_status) if a && driver_id}
    elsif options[:parser_type] && options[:parser_type] == 'milestones_towneair'
      towneair_status = YAML::load(File.open(File.join(Rails.root, "config", "towneair.yml")))
      user = User.find_by_login('TowneAir')
      driver_id = user.id if user
      self.data.actions.each {|a| create_milestones_towneair(a, driver_id, towneair_status) if a && driver_id}
    elsif options[:parser_type] && options[:parser_type] == 'milestones_descartes'
      descartes_status =  YAML::load(File.open(File.join(Rails.root, "config", "descartes.yml")))
      user = User.find_by_login('Descartes')
      
      driver_id = user.id if user
      self.data.actions.each {|a| create_milestones_descartes(a, driver_id, descartes_status) if a && driver_id}
    else
      self.data.actions.each {|a| create_shipment(a) if a}
    end

  rescue => e
    @errors << {
      :shipment_id => 'NA',
      :message => e.message,
      :full_message => e.message
    }
    puts self.errors.last[:full_message]
  end

  def default_files_path
    File.join(Rails.root, "lib", "parser")    
  end

  def create_milestones_descartes(action, driver_id, status_maps)
    
    return if action.empty? 
    
    mawb = action[0][0].to_s.sub('-', '') if action[0][0].to_s.include? '-'
    #Real mawb only 11 characters
    mawb = mawb[0..10]
    shipments = Shipment.where('mawb = ?', mawb)
    return if shipments.nil? || (shipments && shipments.count == 0)
    shipments.each do |shipment|
        shipment_id = shipment.id   
        months =  { "JAN" => 1, "FEB" => 2 , "FEB" => 2, "MAR" => 3, "APR" => 4, "MAY" => 5, "JUN" => 6, "JUL" => 7, "AUG" => 8, "SEP" => 9, "OCT" => 10, "NOV" => 11, "DEC" => 12}
        #Get message of each actions
        fsa_messages = action[1..-1]
        #Store date to update created_at for event action does't have datetime
        pre_time = nil
        fsa_messages.each do |m|
            wordtrak_status = status_maps['descartes_wt'][m[0]]
            #Check this status action exist in milestone or not
            #Skip for OSI status code
            if m[0] == 'OSI'|| m[0] == 'DIS'
                next
            end
            #Create new milestone
            milestone = Milestone.new
            milestone.shipment_id = shipment_id
            milestone.driver_id = driver_id
            milestone.completed = 1
            milestone.action = status_maps['wt_status']["#{wordtrak_status}"]
            milestone.action_code = wordtrak_status
            
            begin
                # Ready parse time data to UTC timezone (is current timezone config)
                Time.zone = "UTC"
                time_now = Time.now
                hour = "00"
                minute = "00"
                second = "00"
                date = time_now.day.to_s
                month = time_now.month.to_s
                year = time_now.year.to_s
                ################################################
                # Get receive time from data file FSA
                # Example data
                ################################################
                # QU SFOTRPA
                # .ZRHFMLX 281936
                # FSA/6
                # 724-13941152SFOMAD/T3K84.0
                # DLV/20JAN0710/MAD/T3K84.0
                #################################################
                data_array = self.data.data.gsub(/\n/, '~').split('~')
                if ! data_array.blank? && data_array.count > 1
                    # Time string line 2, the second string text with partern DDHHMM (D= day, H= hour, M= minute) 
                    string_time = data_array[1].split(' ')[1]
                    #Check valid before parse time
                    if ! string_time.match(/^[0-9]+$/).blank? && string_time.length > 4
                        date = string_time[0..1]
                        hour = string_time[2..3]
                        minute = string_time[4..5]
                    end
                end
                
                # Get datetime section from array
                date_section = m[1]
                
                # Check valid timestamp
                if ! months.has_key?(date_section[2..4])
                    date_section = m[2]
                end
                
                is_date_format_ddmm = true
                if months.has_key?(date_section[2..4])
                    if date_section.length > 5 #Date format DDMMHHMM
                       hour = date_section[5..6]
                       minute = date_section[7..8]
                       is_date_format_ddmm = false
                    end
                    date = date_section[0..1]
                    month = months["#{date_section[2..4]}"]
                end
                
                if month.to_i < 10
                    month ="0#{month}"
                end
                
                # Parse time data and set to created_at of milestone
                pre_time = "#{year}-#{month}-#{date} #{hour}:#{minute}:#{second}"
                milestone.created_at = Time.zone.parse(pre_time)
                
                #Check milestone exist or not
                
                if is_date_format_ddmm
                    #With format DDMM, only need check created_at.day and created_at.month of milestone to make sure record is duplicate
                    have_duplicate = false
                    milestone_exist = Milestone.where(:shipment_id => milestone.shipment_id, :driver_id => milestone.driver_id, :completed => 1, :action => milestone.action,:action_code => milestone.action_code)
                    milestone_exist.each do |m|
                        if m.created_at.utc.day.to_i == date.to_i && m.created_at.utc.month.to_i == month.to_i
                            have_duplicate = true
                        end
                    end
                    
                    if ! have_duplicate
                        milestone_exist = nil
                    end
                else
                    milestone_exist = Milestone.where(:shipment_id => milestone.shipment_id, :driver_id => milestone.driver_id, :completed => 1, :action => milestone.action,:action_code => milestone.action_code, :created_at => milestone.created_at)
                end
                
                if milestone_exist.blank?
                    #Check milestone save success or not
                    if milestone.save
                        #Update WordTrak
                        #Check setting
                        setting = Setting.find_by_name('EnableWTUpdateStatus')
                        
                        if setting && setting.value == '1'
                            action_code = milestone.action_code
                            # if TRANSPAK['AT7'].has_key?(milestone.action_code)
                                # action_code = TRANSPAK['AT7'].key(milestone.action_code)
                            # end
                            
                            # #action code invalid, don't update WordTrak
                            # if action_code.nil?
                                # puts "***************** Invalid action status code when update Status Wordtrak!  for Shipemt with HAWB: #{shipment.hawb}, milestone.action_code: #{milestone.action_code}"
                                # Rails.logger.info "***************** Invalid action status code when update Status Wordtrak!  for Shipemt with HAWB: #{shipment.hawb}, milestone.action_code: #{milestone.action_code}"
                                # next
                            # end
                            
                            hawb = shipment.hawb  
                            piece_count = shipment.piece_count
                            #Call update status service from WordTrak             
                            client = Savon.client("http://freight.transpak.com/WTKServices/Shipments.asmx?WSDL")
                            response = client.request :update_status, body: {"HandlingStation" => "", "HAWB" => hawb, "UserName" => "instatrace", "StatusCode" => action_code}
                            if response.success?
                               data = response.to_array(:update_status_response, :update_status_result).first
                               if data == true
                                  puts "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                                  Rails.logger.info "*****************SUCCESS Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                               else
                                  puts "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                                  Rails.logger.info "*****************ERROR Update Status Wordtrak!  for Shipemt with HAWB: #{hawb}"
                               end
                            end
                        end
                        #End update WordTrak
                    else
                      @errors << {
                        :shipment_id => milestone.shipment_id,
                        :message => milestone.errors.full_messages.join("; "),
                        :full_message => "Milestone with shipment ID: (#{milestone.shipment_id}) was not saved due to next errors: #{milestone.errors.full_messages.join("; ")}"
                      }
                      puts self.errors.last[:full_message]
                    end
                    #End check milestone save success or not
                end
                #End check milestone exist or not
            rescue Exception => e
                puts "************************* Descartes paser error: #{e.message}"
                next
            end
        end
           
        puts "****************************Imported Milestone of shipment #ID:#{shipment_id }, HAWB = #{shipment.hawb}, MAWB = #{shipment.mawb}"

    end#end shipments.each 
    
  end

  def create_milestones_forwardair(action, driver_id, status_maps)
    b10 = action.find{|d| d.first.eql? "B10"}
    
    return if action.empty? || !b10 
    
    mawb = ''
    if b10 
      mawb = b10[1][4..-1]        
    end
    
    shipments = Shipment.where('mawb = ?', mawb)

    return if shipments.nil? || (shipments && shipments.count == 0)
    shipments.each do |shipment|
        shipment_id = shipment.id   
        #Create new milestone
        milestone = Milestone.new    
        milestone.shipment_id = shipment_id
        milestone.driver_id = driver_id
        milestone.completed = 1    
        # Default location of Forward Air Inc
        #latitude = 36.1942916
        #longitude = -82.80581699999999

        #zone = RestClient.get("http://api.geonames.org/timezone?lat=#{latitude}&lng=#{longitude}&username=instatrace")    
        #milestone.timezone = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
       
        at7 = action.find{|d| d[0] == "AT7"}
        
        if at7 && at7[1]        
          milestone.action = status_maps['AT7'][at7[1]]
          milestone.action_code = at7[1]
        end        

        utc_offset = nil
        if at7 && at7[7]           
           utc_offset = -6.0 if at7[7] == 'CT'
           utc_offset = -5.0 if at7[7] == 'ET'
           utc_offset = -8.0 if at7[7] == 'PT'
           utc_offset = -5.0 if at7[7] == 'LT'
        end

        if at7 && at7[5] && at7[6]            
           milestone.created_at =DateTime.parse(at7[5] + at7[6]).in_time_zone(ActiveSupport::TimeZone[utc_offset].name)
        end
       
        unless milestone.save!          
          @errors << {
            :shipment_id => milestone.shipment_id,
            :message => milestone.errors.full_messages.join("; "),
            :full_message => "Milestone with shipment ID: (#{milestone.shipment_id}) was not saved due to next errors: #{milestone.errors.full_messages.join("; ")}"
          }
          puts self.errors.last[:full_message]
        end            

        puts "****************************Imported Milestone of shipment #ID:#{shipment_id }, HAWB = #{shipment.hawb}, MAWB = #{shipment.mawb}"

    end#end shipments.each 
           
  end
  
  def create_milestones_towneair(action, driver_id, status_maps)
    b10 = action.find{|d| d.first.eql? "B10"}
    
    return if action.empty? || !b10 
    
    mawb = ''
    if b10 
      mawb = b10[1]        
    end
    
    shipments = Shipment.where('mawb = ?', mawb)

    return if shipments.nil? || (shipments && shipments.count == 0)
    shipments.each do |shipment|
        shipment_id = shipment.id   
        #Create new milestone
        milestone = Milestone.new    
        milestone.shipment_id = shipment_id
        milestone.driver_id = driver_id
        milestone.completed = 1    
        # Default location of Forward Air Inc
        #latitude = 36.1942916
        #longitude = -82.80581699999999

        #zone = RestClient.get("http://api.geonames.org/timezone?lat=#{latitude}&lng=#{longitude}&username=instatrace")    
        #milestone.timezone = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
       
        at7 = action.find{|d| d[0] == "AT7"}
        
        if at7 && at7[1]        
          milestone.action = status_maps['AT7'][at7[1]]
          milestone.action_code = at7[1]
        end        

        utc_offset = nil
        if at7 && at7[7]           
           utc_offset = -6.0 if at7[7] == 'CT'
           utc_offset = -5.0 if at7[7] == 'ET'
           utc_offset = -8.0 if at7[7] == 'PT'
           utc_offset = -5.0 if at7[7] == 'LT'
        end

        if at7 && at7[5] && at7[6]            
           milestone.created_at =DateTime.parse(at7[5] + at7[6]).in_time_zone(ActiveSupport::TimeZone[utc_offset].name)
        end
       
        unless milestone.save!          
          @errors << {
            :shipment_id => milestone.shipment_id,
            :message => milestone.errors.full_messages.join("; "),
            :full_message => "Milestone with shipment ID: (#{milestone.shipment_id}) was not saved due to next errors: #{milestone.errors.full_messages.join("; ")}"
          }
          puts self.errors.last[:full_message]
        end            

        puts "****************************Imported Milestone of shipment #ID:#{shipment_id }, HAWB = #{shipment.hawb}, MAWB = #{shipment.mawb}"

    end#end shipments.each 
           
  end
  
  def create_shipment(action)
    b10 = action.find{|d| d.first.eql? "B10"}
    b2 = action.find{|d| d.first.eql? "B2"}

    return if action.empty? || !b10 && !b2

    if b10 
      hawb = b10[1][3..-1]
      shipment_id = b10[2]
      carrier_scac_code = b10[3] if b10[3]
    else
      hawb = b2[4][3..-1]
      #shipment_id = b4[2]
      carrier_scac_code = b2[2] if b2[2]
    end
    
    shipment = Shipment.find_or_initialize_by_hawb hawb
    shipment.shipment_id = shipment_id
    shipment.ship_date = data.ship
    shipment.carrier_scac_code = carrier_scac_code
    
    # SH Ship From Information, shipper
    n1 = action.find{|d| d[0] == "N1" && d[1] == "SH"}
    if n1 && n1[2]
      shipment.shipper = n1[2]
      idx = action.index(action[action.index(n1).next])
  
      #  Address N3
      shipment.origin = action[idx][1] if action[idx]
      
      # Location info N4
      shipment.origin = action[idx][1] + ' ' + action[idx+1].slice(1..-1).join(', ') rescue shipment.origin

    end

    # CN Ship To Information  
    n1 = action.find{|d| d[0] == "N1" && d[1] == "CN"}
    if n1 && n1[2]
      shipment.consignee = n1[2]
      idx = action.index(action[action.index(n1).next])
      
      #  Address N3
      shipment.destination = action[idx][1] if action[idx]

      # Location info N4
      shipment.destination = action[idx][1] + ' ' + action[idx+1].slice(1..-1).join(', ') rescue shipment.destination
    end

    at7 = action.find{|d| d[0] == "AT7"}
    if at7
      shipment.delivery_date = Time.parse(at7[5] + at7[6]) if at7[1] == 'D1'
    else 
      shipment.delivery_date = nil
    end
      
    
    at8 = action.find{|d| d.first.eql? "AT8"}
    
    shipment.weight = at8[3] if at8[3]
    if at8[4]
      shipment.pieces_total = at8[4].to_i      
    end

    if at8[5]
      shipment.pieces_total += at8[5].to_i
    end
        
    unless shipment.save!
      
      @errors << {
        :shipment_id => shipment.shipment_id,
        :message => shipment.errors.full_messages.join("; "),
        :full_message => "Shipment (#{shipment.shipment_id}) was not saved due to next errors: #{shipment.errors.full_messages.join("; ")}"
      }
      puts self.errors.last[:full_message]
    end
  end
end