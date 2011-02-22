require 'rubygems'
require 'sinatra'

get '/' do
  haml :index
end

post '/migrate' do

end
