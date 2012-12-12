class Parser
  class EDITransaction
    attr_accessor :data, :actions, :ship
    
    def initialize(data, parser_type)
      @data = data
      raise 'File has wrong format' unless self.isa?
      if parser_type && parser_type == 'milestones'
        plain = data.gsub(/\r/, '').split('~').map{|line| line.split('*')}
      else
        plain = data.gsub(/~/, '').gsub(/\n/, '~').gsub(/\r/, '').split('~').map{|line| line.split('*')}
      end
      
      isa = plain.find{|d| d.first.eql? "ISA"}
      self.ship = Time.parse("20" << isa[9] << isa[10])
      until plain.size.zero?
        plain = plain.drop_while{ |el| !el.first.eql?("ST") }
        plain.shift
        (self.actions||=[]) << plain.take_while{ |el| !el.first.eql?("ST") }
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

    self.data = EDITransaction.new(options[:data] || IO.read(files_path), options[:parser_type])
    raise 'Data is not defined.' if self.data.nil?
    forwardair_status = YAML::load(File.open(File.join(Rails.root, "config", "forwardair.yml")))
      
    if options[:parser_type] && options[:parser_type] == 'milestones'
      user = User.find_by_login('ForwardAir')
      driver_id = user.id if user
      self.data.actions.each {|a| create_milestones_forwardair(a, driver_id, forwardair_status) if a && driver_id}
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

