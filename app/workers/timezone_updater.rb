class TimezoneUpdater
  @queue = :timezone_queue

  def self.perform(milestone_id)
    milestone = Milestone.find(milestone_id)
    zone = RestClient.get("http://api.geonames.org/timezone?lat=#{milestone.latitude}&lng=#{milestone.longitude}&username=instatrace")
    timeshift = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
    milestone.update_attribute(:timezone, timeshift)
    Mailer.send_milestone_signature(milestone).deliver if milestone.signature && milestone.signature.email
  end
end
  