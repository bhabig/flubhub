class UsersController < ApplicationController

  get '/signup' do
    if !session[:user_id]
      erb :'users/create_user'
    else
      redirect '/user'
    end
  end

  post '/signup' do
    if params[:username].empty? || params[:email].empty? || params[:password].empty?
      redirect '/signup'
    else
      @user = User.create(params)
      session[:user_id] = @user.id
      redirect '/user'
    end
  end

  get '/login' do
    if !logged_in?
      erb :'users/login'
    else
      redirect "/user"
    end
  end

  post '/login' do
    @user = User.find_by(username: params[:username])
    if @user && @user.authenticate(params[:password])
      session[:user_id] = @user.id
      redirect "/user"
    else
      redirect "/signup"
    end
  end

  get '/user' do
    if logged_in?
      @user = current_user
      erb :'users/show_user'
    else
      redirect '/login'
    end
  end


  get '/users/:id/edit' do
    if logged_in?
      @user = current_user
      erb :'users/edit_user'
    end
  end

  patch '/users/:id' do
    if logged_in?
      @user = current_user
      @user.update(username: params[:username]) unless params[:username].empty?
      @user.update(email: params[:email]) unless params[:email].empty?
      @user.update(password: params[:password]) unless params[:password].empty?
      redirect '/user'
    else
      redirect '/login'
    end
  end

  get '/logout' do
    if logged_in?
      session.destroy
      redirect '/'
    else
      redirect '/'
    end
  end

  get '/users/delete' do
    if logged_in?
      @user = current_user
      session.destroy
      @user.destroy
      redirect '/signup'
    else
      redirect '/login'
    end
  end
end
