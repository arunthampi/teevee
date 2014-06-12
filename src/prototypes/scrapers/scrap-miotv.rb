#!/usr/bin/env ruby

=begin
scrap-miotv.rb is a script that is meant to be ran as a cron job.
The goal of the script is to scrap tv guide of all mio TV channels.
=end

require 'uri'
require 'net/http'
require 'date'
require 'nokogiri'

# 1 week
today = Date.today
days_to_scrap = 7

uri = URI.parse('http://mio.singtel.com/')

Net::HTTP.start(uri.host, uri.port) do |http|
  (today...today + days_to_scrap).map do |date|
    d_value = date.strftime('%m/%d/%Y').gsub(/0?(\d)\/0?(\d)\/(\d{4})/, '\1/\2/\3')
    puts "DATE: #{d_value}"
    t_value = '00:00:00' # Always start from midnight
    
    query_string = "?d=#{d_value}&t=#{t_value}"
    response = http.get("/miotv/programme-guide_content.asp#{query_string}")
    
    if response.kind_of? Net::HTTPOK then
      headers = Nokogiri::HTML(response.body).xpath('(//div[@class="headerEpg"]/div[@class="headerEpgItemOne"])[2]')
      mains = Nokogiri::HTML(response.body).xpath('(//div[@class="mainEpg"]/div[@class="mainEpgItemOne"])[2]')
      
      header = headers.first
      main = mains.first
      begin
        if not main.nil? then
          total_width = 0
          puts "  CHANNEL: #{header.inner_text.to_s}"
          main.css('div.mainEpgItemEntry').each do |show|
            width = show.attribute('style').to_s.gsub(/WIDTH:(\d+)px/, '\1')
            total_width += width.to_i
            # Per 200 `width` is an hour.
            # TODO: (stan@d--buzz.com) Calculate the exact time start and end using `date` and `width`.
            puts "    #{width} => #{show.inner_text.to_s}"
          end
          # TODO: (stan@d--buzz.com) Inconsistent total width. Expecting 4800 but actual value fluctuate in a higher range.
          puts "==== TOTAL WIDTH: #{total_width} ===="
        end
        
        header = header.next_sibling
        main = main.next_sibling
      end until header.nil? #&& main.nil?
    end
  end
end