class NewStatusMapping < ActiveRecord::Migration
  def self.up
    #Update  TND: Tendered_to_Carrier   =>  TN3: Tendered_to_Carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'TN3', action = 'Tendered_to_Carrier' WHERE BINARY action = 'Tendered_to_Carrier' and action_code = 'TND'
    SQL
    
    #Update  AR3: Recovered_-_Dest_Terminal =>  AR3: Recovered_from_Carrier
    execute <<-SQL
      UPDATE milestones set action = 'Recovered_from_Carrier' WHERE BINARY action = 'Recovered_-_Dest_Terminal' and action_code = 'AR3'
    SQL
    
    #Update  TND: tendered_to_carrier   =>  TN3: tendered_to_carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'TN3', action = 'tendered_to_carrier' WHERE BINARY action = 'tendered_to_carrier' and action_code = 'TND'
    SQL
    
    #Update  REC: recovered_from_carrier    =>  AR3: recovered_from_carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'AR3', action = 'recovered_from_carrier' WHERE BINARY action = 'recovered_from_carrier' and action_code = 'REC'
    SQL
    
    #Update  RT5: en_route_to_carrier   =>  TR2: en_route_to_carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'TR2', action = 'en_route_to_carrier' WHERE BINARY action = 'en_route_to_carrier' and action_code = 'RT5'
    SQL
  end

  def self.down
    #Update  TND: Tendered_to_Carrier   =>  TN3: Tendered_to_Carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'TND', action = 'Tendered_to_Carrier' WHERE BINARY action = 'Tendered_to_Carrier' and action_code = 'TN3'
    SQL
    
    #Update  AR3: Recovered_-_Dest_Terminal =>  AR3: Recovered_from_Carrier rollback
    execute <<-SQL
      UPDATE milestones set action = 'Recovered_-_Dest_Terminal' WHERE BINARY action = 'Recovered_from_Carrier' and action_code = 'AR3'
    SQL
    
    #Update  TND: tendered_to_carrier   =>  TN3: tendered_to_carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'TND', action = 'tendered_to_carrier' WHERE BINARY action = 'tendered_to_carrier' and action_code = 'TN3'
    SQL
    
    #Update  REC: recovered_from_carrier    =>  AR3: recovered_from_carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'REC', action = 'recovered_from_carrier' WHERE BINARY action = 'recovered_from_carrier' and action_code = 'AR3'
    SQL
    
    #Update  RT5: en_route_to_carrier   =>  TR2: en_route_to_carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'RT5', action = 'en_route_to_carrier' WHERE BINARY action = 'en_route_to_carrier' and action_code = 'TR2'
    SQL
  end
end
