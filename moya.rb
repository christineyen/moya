require 'rubygems'
require 'sinatra'
require 'haml'
require 'net/http'
require 'net/https'
require 'uri'
require 'json'

RIL_GET = 'https://readitlaterlist.com/v2/get'
INST_ADD = 'https://www.instapaper.com/api/add'
INST_AUTH = 'https://www.instapaper.com/api/authenticate'



# OAUTH: http://oauth.rubyforge.org/



ERR_UNAUTHORIZED = 'Looks like you provided incorrect credentials! Try again?'
ERR_REMOTE = "Not our fault! Looks like something's up remotely. Try again later."
ERR_VAGUE = "Something mysterious and bad happened. We're on it!"

helpers do
  # Call the ReadItLater API
  def fetch_readitlater_items(username, password)
    data = [['apikey', ENV['RIL_API_KEY']],
            ['username', username],
            ['password', password]]
    url = "#{RIL_GET}?" + data.map{ |k, v| "#{k}=#{v}" }.join('&')
    execute_ssl_get(url)
  end

  def check_inst_credentials(username, password)
    execute_ssl_post(INST_AUTH, username, password, {}, true)
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
  # We will return read items, in updated order, to be sent to Instapaper
  #   url + title
  def convert_ril_json_to_instapaper(ril_items)
    items = ril_items['list'].values.reject{ |h| h['state'] == '1' }.
      sort_by{ |elt| elt['time_updated'] }
    items.map do |item|
      { :url => item['url'], :title => item['title'] }
    end
  end

  # Call the Instapaper API to create all the items
  def create_instapaper_items(username, password, item)
    execute_ssl_post(INST_ADD, username, password, item, true)
  end

  def execute_ssl_get(url)
    uri = URI.parse(url)

    request = Net::HTTP::Get.new(uri.request_uri)
    ssl_request(uri, request)
  end

  def execute_ssl_post(url, username, password, data, basic_auth = false)
    uri = URI.parse(url)

    request = Net::HTTP::Post.new(uri.request_uri)
    if basic_auth
      request.basic_auth(username, password)
    else
      data.merge({ 'username' => username, 'password' => password })
    end
    request.set_form_data(data)
    ssl_request(uri, request)
  end

  def ssl_request(uri, request)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.request(request)
  end

  def decode_ril_errors(code)
    case code
    when '400'
      'Looks like we messed up - email us and let us know?'
    when '401'
      ERR_UNAUTHORIZED
    when '403'
      "Looks like we're too popular for our own good. Please wait a bit for us to go back under our rate limit."
    when '503'
      ERR_REMOTE
    else
      ERR_VAGUE
    end
  end

  def decode_inst_errors(code)
    case code
    when '403'
      ERR_UNAUTHORIZED
    when '500'
      ERR_REMOTE
    else
      ERR_VAGUE
    end
  end
end

get '/' do
  haml :index
end

post '/ready' do
  errors = {}
  items = []

  # Check and handle ReadItLater errors
  ril_response = fetch_readitlater_items(
      params['ril']['username'], params['ril']['password'])
  unless ril_response.code == '200'
    errors['ReadItLater'] = decode_ril_errors(ril_response.code)
  end

  # Check for and handle Instapaper errors
  un = params['inst']['username']
  pw = params['inst']['password']
  inst_response = check_inst_credentials(un, pw)
  unless inst_response.code == '200'
    errors['Instapaper'] = decode_inst_errors(inst_response.code)
  end

  if errors.empty?
    json = JSON.parse(ril_response.body)
    items = convert_ril_json_to_instapaper(json)
  end

  content_type :json
  { :items => items,
    :errors => errors,
    :username => un,
    :password => pw }.to_json
end

post '/migrate' do
  # It's unclear why we do this - bear with me
  item = { 'title' => params['title'], 'url' => params['url'] }
  resp = create_instapaper_items(params['username'], params['password'], item)

  content_type :json
  { :code => resp.code, :url => params['url'] }.to_json
end

