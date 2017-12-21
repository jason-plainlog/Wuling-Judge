require 'sinatra'

$service_name = 'Wuling Judge'

get '/' do
	@title = 'Home'
	erb :index
end

get '/about' do
	@title = 'About'
	erb :about
end