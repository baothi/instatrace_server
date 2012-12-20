class AddDescartesUser < ActiveRecord::Migration
  def self.up
  	  User.create! do |r|
  	  	r.first_name = 'Descartes'
  	  	r.last_name  = 'FTP'
  	  	r.login      = 'Descartes'
	      r.email      = 'descartes@instatrace.com'
	      r.password   = 'de3c@rt3s'
	      r.phone      = '100100100'
	      r.password_confirmation = 'de3c@rt3s'
	      r.role_id    = 2
	      r.activation_code = 'descartes'	      
	    end
  end

  def self.down
  	User.find_by_login('Descartes').try(:delete)
  end
end
