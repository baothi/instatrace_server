class AddForwardairUser < ActiveRecord::Migration
  def self.up
  	  User.create! do |r|
  	  	r.first_name = 'Forward'
  	  	r.last_name  = 'Air'
  	  	r.login      = 'ForwardAir'
	      r.email      = 'forwardair@instatrace.com'
	      r.password   = 'forw@rd@ir'
	      r.phone      = '100100100'
	      r.password_confirmation = 'forw@rd@ir'
	      r.role_id    = 2
	      r.activation_code = 'forwardair'	      
	    end
  end

  def self.down
  	User.find_by_login('ForwardAir').try(:delete)
  end
end
