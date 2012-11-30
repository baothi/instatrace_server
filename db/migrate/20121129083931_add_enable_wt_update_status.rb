class AddEnableWtUpdateStatus < ActiveRecord::Migration
  def self.up
  	  Setting.create! do |r|
  	  	r.name = 'EnableWTUpdateStatus'
  	  	r.value  = '1'
  	  	r.description  = 'Enable WordTrak Update Status ( Turn on: 1 ; Turn Off : 0)'	            
	    end
  end

  def self.down
  	Setting.find_by_name('EnableWTUpdateStatus').try(:delete)
  end
end
