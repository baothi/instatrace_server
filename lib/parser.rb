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
      if parser_type && parser_type == 'milestones_forwardair'        
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
    descartes_status = nil
      
    if options[:parser_type] && options[:parser_type] == 'milestones_forwardair'
      forwardair_status = YAML::load(File.open(File.join(Rails.root, "config", "forwardair.yml")))
      user = User.find_by_login('ForwardAir')
      driver_id = user.id if user      
      self.data.actions.each {|a| create_milestones_forwardair(a, driver_id, forwardair_status) if a && driver_id}
    
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
    transpak = action.find{|d| d.first.eql? "QP SFOTRPA"}
    
    return if action.empty? 
       
    mawb = action[0][0].to_s.sub('-', '') if action[0][0].to_s.include? '-'
      
    shipments = Shipment.where('mawb = ?', mawb)
    return if shipments.nil? || (shipments && shipments.count == 0)
    shipments.each do |shipment|
        shipment_id = shipment.id   
        #Create new milestone
        milestone = Milestone.new    
        milestone.shipment_id = shipment_id
        milestone.driver_id = driver_id
        milestone.completed = 1    

        months =  { "JAN" => 1, "FEB" => 2 , "FEB" => 2, "MAR" => 3, "APR" => 4, "MAY" => 5, "JUN" => 6, "JUL" => 7, "AUG" => 8, "SEP" => 9, "OCT" => 10, "NOV" => 11, "DEC" => 12}
        fsa_messages = action[1..-1]
        fsa_messages.each do |m|
            wordtrak_status = status_maps['descartes_wt'][m[0]]
            milestone.action = status_maps['wt_status']["#{wordtrak_status}"]
            milestone.action_code = wordtrak_status              
            hour = "00"
            minute = "00"
            second = "00"
               
            if m[2].length > 5 #Date format DDMMHHMM
               hour = m[2][5..6]
               minute = m[2][7..8]      
            end
            # Ready parse time data to UTC timezone (is current timezone config)
            Time.zone = "UTC"
            date = m[2][0..1]
            month = months["#{m[2][2..4]}"]
            year = Time.now.year
            
            if  month.to_i < 10
                month ="0#{month}"
            end
            # Parse time data and set to created_at of milestone
            milestone.created_at = Time.zone.parse("#{year}-#{month}-#{date} #{hour}:#{minute}:#{second}")
            unless milestone.save!
              @errors << {
                :shipment_id => milestone.shipment_id,
                :message => milestone.errors.full_messages.join("; "),
                :full_message => "Milestone with shipment ID: (#{milestone.shipment_id}) was not saved due to next errors: #{milestone.errors.full_messages.join("; ")}"
              }
              puts self.errors.last[:full_message]
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

