class Mailersecond < ActionMailer::Base
  default :from => "jnguyenhoa@gmail.com"

  def milestone_damaged_notifier(milestone)
    @milestone = milestone
    subject = "Shimpent #{milestone.shipment.hawb} has reported Over, Short or Damaged"
    
    recipients = Array.new
    agent = Agent.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Agent"', milestone.driver_id)
    recipients << agent[0].email if agent[0] && agent[0].email
    
    freightForwarder = Company.joins(:user_relations).where('user_relations.user_id = ? AND user_relations.owner_type = "Company"', milestone.driver_id)
    recipients << freightForwarder[0].email if freightForwarder[0] && freightForwarder[0].email
    
    mail(:to => recipients.join(','), :subject => subject) if milestone.signature.email

  end
end
