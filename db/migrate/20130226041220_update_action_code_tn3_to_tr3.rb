class UpdateActionCodeTn3ToTr3 < ActiveRecord::Migration
  def self.up
    #Update  TN3: Tendered_to_Carrier   =>  TR3: Tendered_to_Carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'TR3', action = 'Tendered_to_Carrier' WHERE BINARY action = 'Tendered_to_Carrier' and action_code = 'TN3'
    SQL
    
    #Update  TN3: tendered_to_carrier   =>  TR3: tendered_to_carrier
    execute <<-SQL
      UPDATE milestones set action_code = 'TR3', action = 'tendered_to_carrier' WHERE BINARY action = 'tendered_to_carrier' and action_code = 'TN3'
    SQL
  end

  def self.down
    #Update  TN3: Tendered_to_Carrier   =>  TR3: Tendered_to_Carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'TN3', action = 'Tendered_to_Carrier' WHERE BINARY action = 'Tendered_to_Carrier' and action_code = 'TR3'
    SQL
    
    #Update  TN3: tendered_to_carrier   =>  TR3: tendered_to_carrier rollback
    execute <<-SQL
      UPDATE milestones set action_code = 'TN3', action = 'tendered_to_carrier' WHERE BINARY action = 'tendered_to_carrier' and action_code = 'TR3'
    SQL
  end
end
