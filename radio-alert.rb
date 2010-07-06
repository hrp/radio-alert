#!/usr/bin/ruby

require 'rubygems'
require 'yesradio'
#  require 'twilio'
# require 'twiliolib'
require 'open-uri'
require 'net/https'

require 'yaml'
CONFIG = YAML::load(File.open('config.yml'))
SID = CONFIG['sid']
TOKEN = CONFIG['token']
CALLER_ID = CONFIG['caller_id']
SEND_TO = CONFIG['send_to']

# class Net::HTTP
#   alias_method :old_initialize, :initialize
#   def initialize(*args)
#     old_initialize(*args)
#     @ssl_context = OpenSSL::SSL::SSLContext.new
#     @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
#   end
# end

# get stations near san francisco
def get_stations_near(city)
  Yesradio::search_stations :loc => city, :max => 50
end

def get_current_song(station)
  Yesradio::get_recent :name => station.name
end

def poll_stations(stations)
  stations = [*stations]
  stations.each do |station|
    puts "#{station.name}: #{station.desc}"
    song = Yesradio::get_recent :name => station.name, :max => 1
    song = [*song]
    look_for(song.first)
  end
end

def look_for(song, artist="Steve Miller")
  unless song.nil?
    puts "#{song.by} - #{song.title}"
    if song.by.include?(artist)
      send_alert(station, song)
    end
  end
end
  

def send_alert(station, song)

  to     = SEND_TO
  
  base_url = "https://api.twilio.com/2008-08-01"
  base_url << "/Accounts/#{SID}/SMS/Messages"
  b_url = "https://#{SID}:#{TOKEN}@api.twilio.com/2008-08-01"
  b_url << "/Accounts/#{SID}/SMS/Messages"
  uri = URI.parse(base_url)
  
  title = song.title rescue 'Title'
  by = song.by rescue 'By'
  station_name = station.name rescue 'Name'
  station_desc = station.desc rescue 'Desc'
  
  message = "#{title} by #{by} is playing on #{station_name} (#{station_desc})."

  param = {
    'From' => CALLER_ID,
    'To' => to,
    'Body' => message
  }
  
  data = "From=#{CALLER_ID}&To=#{to}&Body=#{message}"

  curl =  %{curl -u "#{SID}:#{TOKEN}" -d "#{data}" #{uri}}
  
  puts %x[#{curl}]
  
  
  
  # http = Net::HTTP.new(uri.host, uri.port)
  #   request = Net::HTTP::Post.new(uri.request_uri)
  #   request.basic_auth(SID, TOKEN)
  #   request.set_form_data(param)
  #   puts request
  # response = http.request(request)
  # puts response
  # http.use_ssl = true
  # post = http.post(uri.path, data )
  
  # sms = account.request('SMS/Messages', 'POST', param)
  # resp = account.request("/Calls", 'POST', d)
  # resp.error! unless resp.kind_of? Net::HTTPSuccess
  # puts "code: %s\nbody: %s" % [resp.code, resp.body]
  # puts sms
   # Twilio::Sms.message(caller_id, send_alert_to, "#{song.title} by #{song.by} is playing on #{station.name} (#{station.desc}).") 
                        #
end

place = 'San Francisco, CA'
local_stations = get_stations_near(place)
require 'open-uri'
open('http://google.com')

pid = fork do
  loop do
    poll_stations( local_stations )
    puts 'sleeping...'
    sleep(180)
  end
end

Process.detach(pid)

