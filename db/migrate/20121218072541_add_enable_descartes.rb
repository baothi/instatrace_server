class AddEnableDescartes < ActiveRecord::Migration
  def self.up
  	  Setting.create! do |r|
  	  	r.name = 'EnableDescartesIntegration'
  	  	r.value  = '1'
  	  	r.description  = 'Enable Descartes Integration ( Turn on: 1 ; Turn Off : 0)'	            
	    end	    
  end

  def self.down
  	Setting.find_by_name('EnableDescartesIntegration').try(:delete)  	
  end
end
