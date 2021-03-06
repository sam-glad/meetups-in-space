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

def create_comment(user_id, meetup_id, title, body)
  Comment.create(
    user_id: user_id,
    meetup_id: meetup_id,
    title: title,
    body: body)
end

#===============================Get==================================

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

get '/meetups/:id' do
  @meetup = Meetup.find(params[:id])
  @users = @meetup.users("username, avatar_url")
  @comments = Comment.where(meetup_id: params[:id])
  erb :'meetups/show'
end

get '/create_meetup' do
  authenticate!
  erb :'create_meetup/show'
end

#===============================Post=================================

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
  if signed_in?
    @meetup.users << current_user
    flash[:notice] = "Meetup joined!"
    redirect "/meetups/#{@meetup_id}"
  else
    flash[:notice] = "You must log in to join a meetup!"
    redirect "/meetups/#{@meetup_id}"
  end
end

post '/leave_meetup/:id' do
  @user_id = session[:user_id]
  @meetup_id = params[:id]
  @meetup = Meetup.find(@meetup_id)
  @meetup.users.delete(current_user)
  flash[:notice] = "You have left this meetup."
  redirect "/meetups/#{@meetup_id}"
end

post '/post_comment/:id' do
  @user_id = session[:user_id]
  @username = current_user.username
  @meetup_id = params[:id]
  @meetup = Meetup.find(@meetup_id)
  @comment_title = params[:title]
  @comment_body = params[:body]
  create_comment(@user_id, @meetup_id, @comment_title, @comment_body)
  flash[:notice] = "Comment posted!"
  redirect "/meetups/#{@meetup_id}"
end
