class MilestoneGeocoder
  @queue = :milstone_queue

  def self.perform(milstone_id)
    milestone = Milestone.find(milstone_id)
    #milestone.update_attribute :address, milestone.reverse_geocode_wrap
  end
end
  