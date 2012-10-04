class Location < ActiveRecord::Base
  belongs_to :driver, :class_name => 'User'
  has_and_belongs_to_many :shipments

  validates_presence_of :driver_id, :latitude, :longitude

  reverse_geocoded_by :latitude, :longitude

  after_save do
    if self.address == '-'
      Resque.enqueue(LocationGeocoder, self.id)
    end
  end
  
  def update_shipments
    self.driver.tracking_shipments.each do |shipment|
      shipment.locations.clear
      self.shipments << shipment
    end
  end
end
