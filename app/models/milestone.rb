class Milestone < ActiveRecord::Base
  has_many :damages, :dependent => :destroy
  has_many :milestone_documents, :dependent => :destroy
  
  has_one :signature, :dependent => :destroy
  belongs_to :shipment
  belongs_to :driver, :class_name => 'User'
  
  enum_attr :action, %w(pick-up back_at_base en_route_to_carrier tendered_to_carrier recovered_from_carrier out_for_delivery delivered completed_unloading/recovered departed_origin_erminal arrived_transfer_terminal departed_transfer_terminal arrived_destination_terminal out_for_delivery)
  
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
    unless timezone.nil?
      created_at.in_time_zone(timezone) if created_at
    else
      "Waiting for synchronization..."
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
