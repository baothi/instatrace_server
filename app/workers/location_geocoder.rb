class LocationGeocoder
  @queue = :location_queue

  def self.perform(location_id)  	
    location = Location.find(location_id)
    #location.update_attribute :address, location.reverse_geocode
    location.update_shipments
  end
end
  