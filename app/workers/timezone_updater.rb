class TimezoneUpdater
  @queue = :timezone_queue

  def self.perform(milestone_id)
    milestone = Milestone.find(milestone_id)
    zone = RestClient.get("http://api.geonames.org/timezone?lat=#{milestone.latitude}&lng=#{milestone.longitude}&username=instatrace")
    #zone = '<geonames><timezone tzversion="tzdata2012f"><countryCode>VN</countryCode><countryName>Vietnam</countryName><lat>10.85594755</lat><lng>106.63130029999999</lng><timezoneId>Asia/Ho_Chi_Minh</timezoneId><dstOffset>7.0</dstOffset><gmtOffset>7.0</gmtOffset><rawOffset>7.0</rawOffset><time>2013-01-04 11:23</time><sunrise>2013-01-04 06:12</sunrise><sunset>2013-05-28 10:18</sunset></timezone></geonames>'
    timeshift = Hash.from_xml(zone)["geonames"]["timezone"]["gmtOffset"].to_f
    milestone.update_attribute(:timezone, timeshift)
    Mailer.send_milestone_signature(milestone).deliver if milestone.signature && milestone.signature.email
    Mailer.milestone_damaged_notifier(milestone).deliver if milestone.damaged
  end
end
  