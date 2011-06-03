#!/usr/bin/ruby -w

=begin
scrap-starhub.rb is a script that is meant to be ran as a cron job.
The goal of the script is to scrap tv guide of all Starhub channels.
=end

require 'uri'
require 'net/http'
require 'json'

days_to_scrap = 7

uri = URI.parse('http://tvguide.starhub.com/')

Net::HTTP.start(uri.host, uri.port) do |http|
  g = 'top'
  ch = 'all'
  (0...7).map do |d|
    r = rand
    response = http.get("/schedules?d=#{d}&g=#{g}&ch=#{ch}&r=#{r}")
    if response.kind_of? Net::HTTPOK then
      data = JSON.parse(response.body)
      result = data['a']
      date = result['a']
      puts "DATE: #{date}"
      channels = result['b']
      channels.each do |channel|
        channel_id = channel['a']
        channel_number = channel['b']
        channel_name = channel['c']
        channel_imglink = channel['d']
        channel_programs = channel['e']
        channel_new = channel['f']
        
        puts "  CHANNEL: (#{channel_number}) #{channel_name}"
        channel_programs.each do |program|
          program_id = program['a']
          program_pid = program['b']
          program_title = program['c']
          program_start = program['d']
          program_end = program['e']
          puts "    #{program_start} - #{program_end}: #{program_title}"
        end
      end
    end
  end
end