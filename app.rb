require 'redis'
require 'digest'
require 'sinatra'
require "sinatra/activerecord"
require './settings'
require './models/redis.rb'
require './models/user.rb'
require './models/submission.rb'

set :database, {adapter: "sqlite3", database: "./db/db.sqlite3"}
set :sessions => true

register do
	def auth(type)
		condition do
			redirect "/signin" unless send("is_#{type}?")
		end
	end
end

helpers do
	def is_user?
		@user != nil
	end
end

before do
	@loadtime = Time.now
	@user = User.find_by(id: session[:user_id])
end

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
    session[:user_id] = nil
    @user = nil
	@title = 'Sign in/up'

	erb :signin
end

post '/signin' do
	@title = 'Sign in/up'

	if params['submit'] == 'signin'
		user = User.find_by(email: params['email'])
		if user != nil && user.password == Digest::MD5.hexdigest(params['password'])
			session[:user_id] = User.find_by(email: params['email']).id
			redirect '/'
		else
			@msg = [{"type" => "warning", "content" => "Wrong email or password!"}]
		end
	elsif params['submit'] == 'signup'
		if User.exists?(email: params['email'])
			@msg = [{"type" => "warning", "content" => "This email had been registered!"}]
		else
			User.create(email: params['email'], password: Digest::MD5.hexdigest(params['password']))
			@msg = [{"type" => "success", "content" => "Success Registered!"}]
		end
	end

	erb :signin
end

get '/submitions' do
	@title = 'Submitions'

	erb :submitions
end

get '/problems/:pid/submit', :auth => :user do |pid|
	@title = 'Submit'
	@pid = pid

	erb :submit
end

post '/problems/:pid/submit', :auth => :user do |pid|
	begin
		$redis.lpush('queue',JSON.generate({
			'sid' => Submission.count + 1,
			'userid' => @user.id,
			'pid' => params['PID'],
			'lang' => params['lang'],
			'code' => params['CODE']
		}))

		Submission.create(userid: @user.id, lang: params['lang'], pid: params['PID'], status: 0, created_at: Time.now().strftime("%Y-%m-%d %H:%M"))

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

