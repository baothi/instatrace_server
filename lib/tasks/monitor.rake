namespace :monitor do
  desc "Checking any new shipments was created in the last 24 hours by api/post_shipment"
  task :check_shipment_created => :environment do
    shipments = Shipment.find(:all, :conditions => ["created_at >=  now() - INTERVAL 1 DAY"])
    if shipments.empty?
      lastShipment = Shipment.where("is_post_shipment = 1").order("created_at DESC").first
      Mailer.post_shipment_notifier(lastShipment).deliver if lastShipment
    end
  end
  
  task :check_milestone_damaged => :environment do
    milestones = Milestone.where("damaged_notifier = 1")
    if milestones
      milestones.each do |milestone|
        Mailer.damage_notifier(milestone).deliver
        milestone.damaged_notifier = ""
        milestone.save
      end
    end
  end
end