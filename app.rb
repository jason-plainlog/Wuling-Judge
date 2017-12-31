require 'set'
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
		user = User.find_by(name: params['name'])
		if user != nil && user.password == Digest::MD5.hexdigest(params['password'])
			session[:user_id] = user.id
			redirect '/'
		else
			@msg = [{"type" => "warning", "content" => "Wrong email or password!"}]
		end
	elsif params['submit'] == 'signup'
		if User.exists?(name: params['name'])
			@msg = [{"type" => "warning", "content" => "This name had been registered!"}]
		else
			User.create(
				name: params['name'],
				password: Digest::MD5.hexdigest(params['password']),
				alias: params['name'],
				created_at: Time.now().strftime("%Y-%m-%d"),
				accepted: 0,
				submitted: 0,
				status: JSON.generate({
					"accepted" => [],
					"tried" => []
				})
			)
			@msg = [{"type" => "success", "content" => "Success Registered!"}]
		end
	end

	erb :signin
end

get '/settings', :auth => :user do
	@title = 'Settings'

	erb :settings
end


post '/settings', :auth => :user do
	@title = 'Settings'

	if @user.password == Digest::MD5.hexdigest(params['password'])
		@user.info = params['info']
		@user.alias = params['alias'] if params['alias'] != ""
		@user.password = Digest::MD5.hexdigest(params['new_password']) if params['new_password'] != ""
		@user.save
		@msg = [{"type" => "success", "content" => "Settings Saved"}]
	else
		@msg = [{"type" => "warning", "content" => "Wrong Password!"}]
	end

	erb :settings
end

get '/submissions' do
	@title = 'Submissions'

	erb :submissions
end

get '/users/:id' do |id|
	@display = User.find_by(id: id)
	halt(404) if @display == nil

	@title = @display.alias
	@status = JSON.parse(@display.status)

	erb :user
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

		Submission.create(userid: @user.id,lang: params['lang'], pid: params['PID'], status: 0, created_at: Time.now().strftime("%Y-%m-%d %H:%M"))
		status = JSON.parse(@user.status)
		status['tried'] = status['tried'].to_set.add(params['PID']).to_a
		@user.status = JSON.generate(status)
		@user.submitted += 1
		@user.save

		redirect '/submissions'
	rescue
		@msg = [{"type" => "warning", "content" => "System busy! Please wait a second and submit again."}]
	end

	@title = 'Submit'
	@pid = params['PID']
	@code = params['CODE']

	erb :submit
end

get '/ranks' do
	@title = 'Ranks'

	erb :ranks
end

get '/reset' do
	$redis.flushall()
	$redis.set('docker', 0)
	redirect '/submissions'
end

not_found do
  status 404
  redirect '/'
end
