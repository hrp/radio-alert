#!/usr/bin/ruby

require 'rubygems'
require 'yesradio'
require 'open-uri'
require 'yaml'

CONFIG = YAML::load(File.open('config.yml'))
SID = CONFIG['sid']
TOKEN = CONFIG['token']
CALLER_ID = CONFIG['caller_id']
SEND_TO = CONFIG['send_to']


# 
# Get stations near a particular city
#
def get_stations_near(city, max=50)
  Yesradio::search_stations :loc => city, :max => max
end

#
# Get the current playing song for a station
#
def get_current_song(station)
  Yesradio::get_recent :name => station.name
end

#
# Check a set of radio stations for a currently playing artist.
#
def poll_stations(stations, artist)
  stations = [*stations]
  stations.each do |station|
    puts "#{station.name}: #{station.desc}"
    song = Yesradio::get_recent :name => station.name, :max => 1
    song = [*song]
    unless song.first.nil?
      puts "#{song.first.by} - #{song.first.title}"
      if song.first.by.include?(artist)
        p artist
        send_alert(station, song.first)
      end
    end
  end
end
  
#
# Send an alert to the default number 
#
def send_alert(station, song, to=SEND_TO)

  uri = make_url
  
  title = song.title || 'Title'
  by = song.by || 'Artist'
  station_name = station.name || 'Name'
  station_desc = station.desc || 'Description'
  
  message = "#{title} by #{by} is playing on #{station_name} (#{station_desc})."

  params = {
    'From' => CALLER_ID,
    'To' => to,
    'Body' => message
  }

  data = URI.escape(params.collect{|k,v| "#{k}=#{v}"}.join('&'))
  
  command =  %{curl -u "#{SID}:#{TOKEN}" -d "#{data}" #{uri}}
  
  puts %x[#{ command }]
  
end

# 
# Make request url
#
def make_url(sid=SID)
  base_url = "https://api.twilio.com/2008-08-01"
  base_url << "/Accounts/#{sid}/SMS/Messages"
  uri = URI.parse(base_url)
end

#
# Monitor stations for a certain artist.
#
def monitor(artist, place, period=180)
  local_stations = get_stations_near(place)
  pid = fork do
    loop do
      poll_stations( local_stations , artist )
      puts 'sleeping...'
      sleep(period)
    end
  end
  Process.detach(pid)
end

artist = "Santana"
place = "San Francisco, CA"
monitor( artist, place )

