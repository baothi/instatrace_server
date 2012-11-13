class MilestoneGeocoder
  @queue = :milstone_queue

  def self.perform(milstone_id)
    milestone = Milestone.find(milstone_id)
    geo = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]  	
    
    if geo
      address = ''
      if geo.data["address_components"] &&  geo.data["address_components"][5] && geo.data["address_components"][5]["short_name"]
        address = geo.city + ", " + geo.data["address_components"][5]["short_name"]
      else
        address = geo.city + ", " + geo.state
      end
        
      milestone.update_attribute :address, address
    end
    
    #milestone.update_attribute :address, milestone.reverse_geocode_wrap
  end
end
  