require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'

RIL_TEMPLATE = 'https://readitlaterlist.com/v2/get?username=USERNAME&password=PASSWORD&apikey=APIKEY&count=2'

helpers do
  # Call the ReadItLater API
  def fetch_readitlater_items(username, password)
    ril_url = RIL_TEMPLATE.gsub(/APIKEY/, ENV['RIL_API_KEY']).
        gsub(/USERNAME/, params['ril']['username']).
        gsub(/PASSWORD/, params['ril']['password'])

    uri = URI.parse(ril_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)

    JSON.parse(response.body)
  end
end

get '/' do
  haml :index
end

post '/migrate' do
  raise json.inspect

  haml :migrate
end
