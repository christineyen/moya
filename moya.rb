require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'

RIL_TEMPLATE = 'https://readitlaterlist.com/v2/get?username=USERNAME&password=PASSWORD&apikey=APIKEY&count=5'
INST_TEMPLATE = 'https://www.instapaper.com/api/add'

helpers do
  # Call the ReadItLater API
  def fetch_readitlater_items(username, password)
    ril_url = RIL_TEMPLATE.gsub(/APIKEY/, ENV['RIL_API_KEY']).
        gsub(/USERNAME/, username).
        gsub(/PASSWORD/, password)

    uri = URI.parse(ril_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end

  # Items are passed in (via RIL) in the following format:
  # { 'list' =>
  #   { _id_1_ =>
  #     { 'time_updated' => __,
  #       'title' => __,
  #       'time_added' => __,
  #       'url' => __,
  #       'item_id' => __,
  #       'state' => __ }, # '0' is unread; '1' is read
  #   { _id_2_ => .....
  # We will return read items, in added order, to be sent to Instapaper:
  #   url + title
  def convert_ril_json_to_instapaper(ril_items)
    items = ril_items['list'].values.sort_by{ |elt| elt['time_added'] }
    items.map do |item|
      { :url => item['url'], :title => item['title'] }
    end
  end

  # Call the Instapaper API to create all the items
  def create_instapaper_items(username, password, item)
    uri = URI.parse(INST_TEMPLATE)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth(username, password)
    request.set_form_data({ 'title' => item[:title], 'url' => item[:url] })
    http.request(request)
  end
end

get '/' do
  haml :index
end

post '/migrate' do
  ril_items = fetch_readitlater_items(
      params['ril']['username'], params['ril']['password'])
  raise "error! #{ril_items.code} received" unless ril_items.code == '200'

  json = JSON.parse(ril_items.body)
  inst_items = convert_ril_json_to_instapaper(json)

  inst_username = params['inst']['username']
  inst_password = params['inst']['password']
  inst_items.each do |item|
    resp = create_instapaper_items(inst_username, inst_password, item)
  end

  #raise ril_items.inspect

  haml :migrate
end
