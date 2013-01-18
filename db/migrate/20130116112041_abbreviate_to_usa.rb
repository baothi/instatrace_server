class AbbreviateToUsa < ActiveRecord::Migration
  def self.up
    #Abbreviate UNITED STATES OF AMERICA to USA
    execute <<-SQL
      update shipments set origin = REPLACE(origin, 'UNITED STATES OF AMERICA', 'USA'), destination = REPLACE(destination, 'UNITED STATES OF AMERICA', 'USA') WHERE origin LIKE '%UNITED STATES OF AMERICA%' or destination LIKE '%UNITED STATES OF AMERICA%'
    SQL
  end

  def self.down
    #Abbreviate UNITED STATES OF AMERICA to USA rollback
    execute <<-SQL
      update shipments set origin = REPLACE(origin, 'USA', 'UNITED STATES OF AMERICA'), destination = REPLACE(destination, 'USA', 'UNITED STATES OF AMERICA') WHERE origin LIKE '%USA%' or destination LIKE '%USA%'
    SQL
  end
end
