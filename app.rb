require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

def create_meetup(name, location, description)
  Meetup.create(
    name: name,
    location: location,
    description: description
    )
end

#====================================================================

get '/' do
  @meetups = Meetup.all.order('name asc')
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

# get '/example_protected_page' do
#   authenticate!
# end

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  erb :'meetups/show'
end

get '/create_meetup' do
  authenticate!
  erb :'create_meetup/show'
end

post '/create_meetup' do
  @name = params[:name]
  @location = params[:location]
  @description = params[:description]
  @new_meetup = create_meetup(@name, @description, @location)
  # TODO use ActiveRecord below?
  @id = @new_meetup[:id]
  flash[:notice] = "Your event has been created!"
  redirect "/meetups/#{@id}"
end

post "/join_meetup/:id" do
  @user_id = session[:user_id]
  @meetup_id = params[:id]
  @meetup = Meetup.find(@meetup_id)
  if !@meetup.users.include?(current_user)
    @join = @meetup.users << current_user
    flash[:notice] = "Event joined!"
  else
    flash[:notice] = "You're already signed up for this meeting!"
  end
  redirect "/meetups/#{@meetup_id}"
end
