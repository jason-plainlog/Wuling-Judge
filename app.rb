require 'redis'
require 'sinatra'
require 'usagewatch_ext'
require './models/redis.rb'
require './settings'

get '/' do
	@title = 'Home'

	erb :index
end

get '/about' do
	@title = 'About'

	erb :about
end

get '/signin' do
	@title = 'Sign in/up'

	erb :signin
end

post '/signin' do
	if params['submit'] == 'signin'
		'signed in'
	else
		'signed up'
	end
end

get '/submitions' do
	@title = 'Submitions'

	erb :index
end

get '/problems/:pid/submit' do |pid|
	@title = 'Submit'
	@pid = pid

	erb :submit
end

post '/problems/:pid/submit' do |pid|
	@title = 'Submit'
	@pid = pid

	begin
		$redis.rpush('queue',JSON.generate(params))
		
		@msg = [{"type" => "success", "content" => "Submition had been sent!"}]
	rescue
		@msg = [{"type" => "warning", "content" => "System busy! Please wait a second and submit again."}]
	end

	erb :submit
end