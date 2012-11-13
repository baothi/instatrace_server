class CargoValidator < ActiveModel::EachValidator
  # cargo should be a valid cargo number
  def validate_each(record, att, value)
    record.errors[att] << 'is invalid' unless (value =~ /^\d{11}$/) && ((value[3..-2].to_i%7).to_s == value[-1])
  end
end

class Shipment < ActiveRecord::Base
  include ActiveModel::Validations
  has_many :milestones, :dependent => :destroy
  has_many :drivers, :through => :milestones
  has_and_belongs_to_many :locations
  has_many :pieces, :dependent => :destroy
  accepts_nested_attributes_for :pieces
  validates :hawb, :presence => true, :uniqueness => {:case_sensitive => false}

  validates_date :ship_date, :allow_blank => true
  validates_date :delivery_date, :allow_blank => true

  scope :none, where('1=2')

  scope :search, lambda {|params|
    params ||= {}
    chain = self.scoped
   
    #  Scope for simple search    
    if params['query'].present? && !params['search_type'].blank?
      chain = chain.where(params['search_type'] => params['query']) 
    elsif !params['service_level'].nil?    
    #  Scope for advanced search
      if params['service_level'] == 'open'
        chain = chain.where(:service_level != 'delivered')
      elsif params['service_level'].present?
        chain = chain.where(:service_level => params['service_level'])
      end
      %w[hawb mawb origin destination consignee shipper].each do |arg|
        chain = chain.where(arg => params[arg]) if params[arg].present?
      end
    elsif User.current && (User.current.operator? || User.current.driver? || User.current.admin?)
      chain = chain.where(:id => User.current.allowed_shipments)
    elsif User.current.nil?
      chain = chain.none
    end

    chain
  }
  
  attr_accessor :search_type, :query
  
  # validates :mawb, :cargo => true, :allow_blank => true
  # validates :hawb, :cargo => true, :allow_blank => true
  
  before_validation do |record|
    record.mawb.gsub!(/\W|_/, '') if record.mawb
    record.hawb.gsub!(/\W|_/, '') if record.hawb
  end

  def hawb_with_scac
    "#{'TPKA' if carrier_scac_code === 'TPKA'}#{hawb}"
  end
  
  def self.data
    Rails.cache.write(:shipment_spec, YAML::load(File.open(File.join(Rails.root, "lib", "parser", "cargo_spec.yml")))) unless Rails.cache.read(:shipment_spec)
    Rails.cache.read(:shipment_spec)
  end
  
  def self.api_search(cargo)
   # return nil if cargo.nil?
    return self.where("hawb = :cargo OR mawb = :cargo", {:cargo => cargo}).first
  end
  
  def damaged?
    !milestones.where(:damaged => true).count.zero?
  end

  def current_status
    self.milestones.last.action rescue ''
  end
  
  def as_json(options={})
    hash = { :shipment_id => shipment_id,
      :pieces => pieces_total,
      :weight => weight,
      :pick_up => [origin, shipper].delete_if{ |field| field.nil? || field.blank?}.join(" - "),
      :destination => [destination, consignee].delete_if{ |field| field.nil? || field.blank?}.join(" - "),
      :damaged => damaged?,
      :hawb => hawb,
      :mawb => hawb
    }
    if options && options.has_key?(:addShip)
      hash = serializable_hash(options)
      hash[:hawb_with_scac] = self.hawb_with_scac
      hash[:ship_date] = self.ship.to_s
      hash[:delivery_date] = self.delivery.to_s
      hash[:current_status] = self.current_status
    end
    return hash
  end

  def last_location
    
    #milestone = self.milestones.order("updated_at DESC").where('address IS NOT NULL').first
    #location = self.locations.order("updated_at DESC").first
   
    # if milestone == nil and location == nil
    #   return '-'
    # end

    # if milestone == nil or  milestone.updated_at == nil
    #   return location.address ? location.address: '-'
    # end

    # if location == nil or location.updated_at == nil
    #   return milestone.address ? milestone.address: '-'
    # end
    
    # if milestone.updated_at > location.updated_at            
    #    return milestone.address ? milestone.address: '-'
    # else      
    #    return location.address ? location.address: '-'
    # end

    result = Hash.new

    stop_tracking_actions = ["back_at_base","delivered","tendered_to_carrier"]
    milestone = self.milestones.order("updated_at DESC").where('action IS NOT NULL').first
    
    if milestone            
       if stop_tracking_actions.include? milestone.action.to_s
         
            result["geo"] = Geocoder.search("#{milestone.latitude},#{milestone.longitude}")[0]
            result["updated_at"] = milestone.created_time_with_timezone
       else        
         
            #Get last location of driver
            location = milestone.driver.locations.order("updated_at DESC").first if milestone.driver
            
            if location && Geocoder.search("#{location.latitude},#{location.longitude}")[0]            
              result["geo"] = Geocoder.search("#{location.latitude},#{location.longitude}")[0]
              result["updated_at"] = location.updated_at                
            end
       end   
    end

    return result
  end
  
private

  def date?
    if !mydate.is_a?(Date)
      errors.add(:mydate, 'must be a valid date') 
    end
  end

end

