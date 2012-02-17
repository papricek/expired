require "rubygems"

require 'open-uri'
require 'nokogiri'
require 'domainapi'
require 'json'
require 'ostruct'
require 'fastercsv'

doc = Nokogiri::HTML(open('http://www.regzone.cz/uvolnovane-domeny/'))

domains = doc.css('tr td.second a').map do |link|
  link.content
end

puts "Domains: #{domains.size}"

domains = domains.select do |domain|
body = open("https://www.google.com/a/#{domain}/").read
	body.match(/\@#{domain}/)
end

domains_with_info = domains.map { |domain|
	data = DomainAPI::use('patrikjira1','bkybuidsnttb')::get('info')::on(domain)
	json_data = JSON.parse(data)
	online_since = json_data['content']['info']['contentData']['siteData']['onlineSince'] rescue ""
	year = online_since.to_s.match(/.+\-(\d{4})/) ? $1 : nil
	OpenStruct.new(:domain => domain, :online_since => online_since, :year => year)
}.sort{|i| i.domain }


filename = "domains_" + Time.now.strftime("%m-%d-%Y") + ".csv"
  
csv = FasterCSV.generate do |csv|
    csv << [
    "Domain",
    "OnlineSince"
    ]
    domains_with_info.each do |d|
      csv << [d.domain, d.online_since]
    end
  end

File.open(filename, 'w') {|f| f.write(csv) }

puts "Done!"
