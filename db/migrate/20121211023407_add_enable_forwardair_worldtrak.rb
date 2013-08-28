class AddEnableForwardairWorldtrak < ActiveRecord::Migration
  def self.up
  	  Setting.create! do |r|
  	  	r.name = 'EnableWorldTrakIntegration'
  	  	r.value  = '1'
  	  	r.description  = 'Enable WordTrak Integration ( Turn on: 1 ; Turn Off : 0)'	            
	    end
	    Setting.create! do |r|
  	  	r.name = 'EnableForwardAirIntegration'
  	  	r.value  = '1'
  	  	r.description  = 'Enable ForwardAir Integration ( Turn on: 1 ; Turn Off : 0)'	            
	    end
  end

  def self.down
  	Setting.find_by_name('EnableWorldTrakIntegration').try(:delete)
  	Setting.find_by_name('EnableForwardAirIntegration').try(:delete)
  end
end
