class Piece < ActiveRecord::Base
	 include ActiveModel::Validations
	 belongs_to :shipment	 
end
