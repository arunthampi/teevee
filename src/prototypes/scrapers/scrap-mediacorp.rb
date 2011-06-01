#!/usr/bin/env ruby

=begin
scrap-mediacorp.rb is a script that is meant to be ran as a cron job.
The goal of the script is to scrap tv guide of all MediaCorp channels.
=end

require 'uri'
require 'net/http'
require 'nokogiri'
require 'cgi'

uri = URI.parse('http://www2.mediacorp.com.sg/')
#p uri
Net::HTTP.start(uri.host, uri.port) do |http|
  # Retrieve the available parameters
  response = http.get('/cgi-bin/tvguide/tvguide_daily_channel_new.asp')
  if response.kind_of? Net::HTTPOK then
    form = Nokogiri::HTML(response.body).css('html > body > form').first
    if not form.nil? and form.has_attribute? 'action' then
      action = form.attribute('action').to_s
      
      # Channels
      channel_parameter_name = 'channel'
      channels = []
      Nokogiri::HTML(response.body).xpath("//input[@name='#{channel_parameter_name}']").each do |channel|
        channels << channel.attribute('value').to_s
      end
      
      # Programmes
      programme_parameter_name = 'prog_type'
      programmes = []
      Nokogiri::HTML(response.body).xpath("//select[@name='#{programme_parameter_name}']/option").each do |programme|
        programmes << programme.attribute('value').to_s
      end
      
      # Dates
      date_parameter_name = 'schdate'
      dates = []
      Nokogiri::HTML(response.body).xpath("//select[@name='#{date_parameter_name}']/option").each do |date|
        dates << date.attribute('value').to_s
      end
      
      # Times
      time_parameter_name = 'schtime'
      times = []
      Nokogiri::HTML(response.body).xpath("//select[@name='#{time_parameter_name}']/option").each do |time|
        times << time.attribute('value').to_s
      end
      
      # Query TV guide for all available parameters
      channels.each do |channel|
      puts "Channel: #{channel}"
      dates.each do |date|
      puts "  Date: #{date}"
      times.each do |time|
      puts "    Time: #{time}"
        data = "#{programme_parameter_name}=#{CGI.escape(programmes.first)}&#{date_parameter_name}=#{CGI.escape(date)}&#{time_parameter_name}=#{CGI.escape(time)}&#{channel_parameter_name}=#{CGI.escape(channel)}"
        response = http.post("/cgi-bin/tvguide/#{action}", data)
        if response.kind_of? Net::HTTPOK then
          Nokogiri::HTML(response.body).xpath('//td[@bgcolor="#666666"]').each_with_index do |show, i|
            colspan = show.attribute('colspan').to_s.to_i
            show_name = show.css('font > b > b').first.inner_text.to_s
            # `colspan` can be use to find the exact time slot of the show.
            # `colspan` is at half an hour a unit.
            # TODO: (stan@d--buzz.com) Calculate the exact time start and end using `time` and `colspan`.
            puts "      #{colspan.to_s} => #{show_name}"
          end
        end
      end
      end
      end
    end
  end
end