class AddEnableTowneair < ActiveRecord::Migration
  def self.up
      Setting.create! do |r|
        r.name = 'EnableTowneAirIntegration'
        r.value  = '1'
        r.description  = 'Enable TowneAir Integration ( Turn on: 1 ; Turn Off : 0)'             
      end
  end

  def self.down
    Setting.find_by_name('EnableTowneAirIntegration').try(:delete)
  end
end
