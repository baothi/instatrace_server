class Milestone < ActiveRecord::Base
  has_many :damages, :dependent => :destroy
  has_many :milestone_documents, :dependent => :destroy
  
  has_one :signature, :dependent => :destroy
  belongs_to :shipment
  belongs_to :driver, :class_name => 'User'
  
  enum_attr :action, %w(pick-up back_at_base en_route_to_carrier tendered_to_carrier recovered_from_carrier out_for_delivery delivered completed_unloading/recovered departed_origin_terminal arrived_transfer_terminal departed_transfer_terminal arrived_destination_terminal Shipment_Delayed Alert_Onfirmed All_Import_Documents_Received On_hand_Dest_terminal Arrived_Dest_Terminal Booked_with_carrier Customs_Released/Cleared Tendered_to_Carrier Routing_Confirmed Recovered_Dest_Terminal Delivered_w/Proof_of_Delivery Picked_up_from_Shipper In_Transit Assigned_to_flight In_Customs_Clearance Shipment_on_Hold Confirmed_On_Board_Carrier Missing_EDI_Translation_Code On_hand_-_Dest_terminal Recovered_-_Dest_Terminal Recovered_from_Carrier Enroute_to_Carrier)
  
  validates :shipment_id, :driver_id, :action, :presence => {:if => :completed?}  
  validates :latitude, :longitude, :numericality => true, :presence => {:if => :completed?}  

  reverse_geocoded_by :latitude, :longitude
  
  accepts_nested_attributes_for :damages, :milestone_documents

  before_save :should_update_timezone

  after_save do
    if @update_timezone == true
      Resque.enqueue(TimezoneUpdater, self.id)
      Resque.enqueue(MilestoneGeocoder, self.id)
    end
  end

  def created_time_with_timezone
    milestone = Milestone.find(self.id)
    if milestone.driver_id.to_s == "214" #Descartes
        #For case Descartes integration, use UTC time zone
        created_at
    else
        #Resque doesn't update timezone in sometime,therefore, need to update timezone of milestone again when the user views milestone list
        if timezone.nil? && milestone.longitude != '0.0' &&  milestone.latitude != '0.0'             
           zone = RestClient.get("http://api.geonames.org/timezone?lat=#{milestone.latitude}&lng=#{milestone.longitude}&username=instatrace")
           #zone = '<geonames><timezone tzversion="tzdata2012f"><countryCode>VN</countryCode><countryName>Vietnam</countryName><lat>10.85594755</lat><lng>106.63130029999999</lng><timezoneId>Asia/Ho_Chi_Minh</timezoneId><dstOffset>7.0</dstOffset><gmtOffset>7.0</gmtOffset><rawOffset>7.0</rawOffset><time>2013-01-04 11:23</time><sunrise>2013-01-04 06:12</sunrise><sunset>2013-01-04 17:43</sunset></timezone></geonames>'
           timeshift = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
           milestone.update_attribute(:timezone, timeshift) 
           "Waiting for synchronization"
        elsif timezone && timezone.to_s !='0.0'
           created_at.in_time_zone(timezone) if created_at   
        else
           #For case Forward Air integration
           created_at 
        end
    end
  end

  def create_address_with_location
      if address.nil?
         milestone = Milestone.find(self.id)
         geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]    
          
         if geo && geo.city && geo.state_code
           address = geo.city + ", " + geo.state_code             
           milestone.update_attribute :address, address
           address
           puts '=================milestone id #{milestone.id}'           
         end
      else
        self.address
      end      
  end

  def should_update_timezone
    @update_timezone = false
    if (self.persisted? == false)
      @update_timezone = true
    elsif (latitude_was_changed? or longitude_was_changed?)
      @update_timezone = true
    end
  end

  def latitude_was_changed?
    self.latitude != Milestone.find(self.id).latitude
  end

  def longitude_was_changed?
    self.longitude != Milestone.find(self.id).longitude
  end

  scope :completed, where(:completed => true)
  
  def damaged?
    self.damaged
  end

  def location?
    self.latitude && self.longitude && (self.latitude + self.longitude != 0)
  end

  def damage_desc
     (self['damage_desc'].blank? && damaged) ? I18n::t(:text_notify_damaged) : self['damage_desc']
  end

  def as_json(options = nil)
    hash = serializable_hash(options)
    hash[:created_time_with_timezone] = self.created_time_with_timezone.to_s
    hash[:created_at] = self.created_at.to_s
    hash[:updated_at] = self.updated_at.to_s      
    hash
  end

  def self.tracking_actions
    %w(pick-up en_route_to_carrier recovered_from_carrier out_for_delivery)
  end

  def reverse_geocode_wrap
    if(self.latitude != 0 or self.longitude != 0)
      self.reverse_geocode
    end
  end

 private

  def update_shipment
    shipment.update_attribute :service_level, self.action.to_s.humanize
  end
end
