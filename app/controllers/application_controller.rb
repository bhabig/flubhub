require './config/environment'

class ApplicationController < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    set :session_secret, "secret_password"
  end

  get '/' do
    if current_user != nil
      @user = current_user
    end
    erb :index
  end

  helpers do
    def current_user
      @user ||= User.find_by_id(session[:user_id])
    end

    def logged_in?
      !!session[:user_id]
    end
  end
end
