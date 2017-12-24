require 'redis'
require 'digest'
require 'sinatra'
require "sinatra/activerecord"
require 'usagewatch_ext'
require './models/redis.rb'
require './models/user.rb'
require './settings'

set :database, {adapter: "sqlite3", database: "./db/db.sqlite3"}

get '/' do
	@title = 'Home'

	erb :index
end

get '/about' do
	@title = 'About'
	@user_count = User.count

	erb :about
end

get '/signin' do
	@title = 'Sign in/up'

	erb :signin
end

post '/signin' do
	if params['submit'] == 'signin'
		if User.find_by(email: params['email']).password == Digest::MD5.hexdigest(params['password'])
			@msg = [{"type" => "success", "content" => "Signed in successfully!"}]
		else
			@msg = [{"type" => "warning", "content" => "Wrong email or password!"}]
		end
	elsif params['submit'] == 'signup'
		if User.exists?(email: params['email'])
			@msg = [{"type" => "warning", "content" => "This email had been registered!"}]
		else
			user = User.create(email: params['email'], password: Digest::MD5.hexdigest(params['password']))
			@msg = [{"type" => "success", "content" => "Success Registered!"}]
		end
	end

	erb :signin
end

get '/submitions' do
	@title = 'Submitions'

	erb :submitions
end

get '/problems/:pid/submit' do |pid|
	@title = 'Submit'
	@pid = pid

	erb :submit
end

post '/problems/:pid/submit' do |pid|
	begin
		$redis.lpush('queue',JSON.generate({
			'sid' => $redis.incr('sid'),
			'pid' => params['PID'],
			'lang' => params['lang'],
			'code' => params['CODE'],
			'create_time' => Time.now().strftime("%Y-%m-%d %H:%M")
		}))
		
		@msg = [{"type" => "success", "content" => "Submition had been sent!"}]
		redirect '/submitions'
	rescue
		@msg = [{"type" => "warning", "content" => "System busy! Please wait a second and submit again."}]
	end

	@title = 'Submit'
	@pid = params['PID']
	@code = params['CODE']

	erb :submit
end

get '/reset' do
	$redis.flushall()
	$redis.set('docker', 0)
	redirect '/submitions'
end

