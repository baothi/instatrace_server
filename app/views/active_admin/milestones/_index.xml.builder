
xml.instruct!
xml.milestones do
  index.each do |milestone|
    xml.milestone do
      xml.shipment_hawb milestone.shipment.hawb.to_s if milestone.shipment
      xml.driver_emal milestone.driver.email.to_s if milestone.driver
      xml.action milestone.action.to_s
      xml.damaged milestone.damaged.to_s
      xml.public milestone.public.to_s
      xml.damage_desc milestone.damage_desc.to_s
      xml.created_at milestone.created_time_with_timezone.to_s
    end
  end
end