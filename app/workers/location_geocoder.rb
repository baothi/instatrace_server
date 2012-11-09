class LocationGeocoder
  @queue = :location_queue

  def self.perform(location_id)  	
    location = Location.find(location_id)
    #location.update_attribute :address, location.reverse_geocode    

    zone = RestClient.get("http://api.geonames.org/timezone?lat=#{location.latitude}&lng=#{location.longitude}&username=instatrace")
    timeshift = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
    milestone.update_attribute(:timezone, timeshift)
    location.update_shipments
  end
end
  