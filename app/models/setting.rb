class Setting < ActiveRecord::Base
    attr_accessible :name, :value, :description
end 