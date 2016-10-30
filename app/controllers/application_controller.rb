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

    def find_order_match_user_id(extra_criteria=nil, current_user=nil)
      @order = Order.find_by_id(params[:order_id])
      if @order.user_id == @user.id && extra_criteria
        yield
      end
    end

		def check_logged_in(&block)
	    if logged_in?
        current_user
		    yield
	    else
		    redirect '/login'
	    end
    end
  end
end
