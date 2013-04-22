module ApplicationHelper
	def locale_urls
		urls = []
		I18n::available_locales.map do |locale|
			options = {}
			options[:class] = 'active' if current_locale == locale
			options[:title] = t(:language, :locale => locale)
			urls << link_to(locale, language_path(locale), options)
		end
		raw(urls.join(' | '))
	end

	def damages_urls(milestone, text = nil)
		urls = []
		milestone.damages.each_with_index do |damage,i| 
        	urls << link_to("#{text}#{i+1}", damage.photo.url, :target => :blank)
        end if milestone.damages
        raw(urls.join(', '))
	end

	def documents_urls(milestone, text = nil)
		urls = []
		milestone.milestone_documents.each_with_index do |document,i| 
        	urls << link_to("#{text}#{i+1}", document.name.url, :target => :blank)
        end if milestone.milestone_documents
        raw(urls.join(', '))
	end

	def google_location_url(latitude,longitude,zoom=17)
		"https://maps.google.com/maps?&q=loc:#{latitude},#{longitude}&z=#{zoom}"
  	end
  	
  def us_states
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

end
