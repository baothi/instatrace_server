namespace :import do
  desc "Parses all shipments data from the files"
  task :shipments => :environment do
    #new_path = Dir.pwd + "/../data/"
    #old_path = Dir.pwd + "/lib/parser/214/old/"

    new_path = "/home/worldtrakftp/"   
    old_path = "/home/worldtrakftp/old/"

    parse_files = Dir.glob(new_path+'EDI*.txt')

    parse_files.each do |file|
      Parser.new(:file_name => file, :path => '')
      FileUtils.mv(file, old_path + Pathname.new(file).basename.to_s)
      puts file
    end
  end

  task :milestones => :environment do   
    forwardair_path = "/home/forwardairftp/"
    parse_files = Dir.glob(forwardair_path+'*.214')
        
    parse_files.each do |file|
      Parser.new(:file_name => file, :path => '',:parser_type => 'milestones')
      FileUtils.mv(file, forwardair_path + Pathname.new(file).basename.to_s)
      puts "==============================Updated Milestones: #{file}"
    end
  end
  
  desc "Remove old shipmetns from database"
  task :remove_shipments => :environment do
    Shipment.joins(:milestones).where('milestones.action = ? AND milestones.updated_at <= ?', 'delivery', Date.today - 6.months).each{|item| item.destroy}
  end



end
