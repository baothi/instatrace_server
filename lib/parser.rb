class Parser
  class EDITransaction
    attr_accessor :data, :actions, :ship
    
    def initialize(data)
      @data = data
      raise 'File has wrong format' unless self.isa?
      plain = data.gsub(/~/, '').gsub(/\n/, '~').gsub(/\r/, '').split('~').map{|line| line.split('*')}
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
    self.data = EDITransaction.new(options[:data] || IO.read(files_path))
    raise 'Data is not defined.' if self.data.nil?
    self.spec = YAML::load(File.open(File.join(Rails.root, "lib", "parser", "cargo_spec.yml")))    
    self.data.actions.each {|a| create_shipment(a) if a}
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

