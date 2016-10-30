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
    check_logged_in do
      @user.orders.each {|o| o.delete if o.items.empty?}
      erb :'users/show_user'
    end
  end


  get '/users/:id/edit' do
    check_logged_in do
      erb :'users/edit_user'
    end
  end

  patch '/users/:id' do
    check_logged_in do
      @user.update(username: params[:username]) unless params[:username].empty?
      @user.update(email: params[:email]) unless params[:email].empty?
      @user.update(password: params[:password]) unless params[:password].empty?
      redirect '/user'
    end
  end

  get '/logout' do
    check_logged_in do
      session.destroy
      redirect '/'
    end
  end

  get '/users/delete' do
    check_logged_in do
      session.destroy
      @user.destroy
      redirect '/signup'
    end
  end
end
