class MilestoneGeocoder
  @queue = :milstone_queue

  def self.perform(milstone_id)
    milestone = Milestone.find(milstone_id)
    geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]  	
    
    if geo && geo.city && geo.state_code
      address = geo.city + ", " + geo.state_code
        
      milestone.update_attribute :address, address
    end
    
    #milestone.update_attribute :address, milestone.reverse_geocode_wrap
  end
end
  