class OrdersController < ApplicationController
  get '/orders' do
    if logged_in?
      @orders = Order.all
      @user = current_user
      redirect '/user'
    else
      redirect '/login'
    end
  end

  get '/orders/new' do
    if logged_in?
      @user = current_user
      erb :'orders/new'
    else
      redirect "/login"
    end
  end

  post '/orders' do
    binding.pry
    
    @order = Order.create(params)

  end

  get '/orders/:id' do

  end

  get '/orders/:id/edit' do

  end

  patch '/orders/:id' do

  end

  delete '/orders/:id/delete' do

  end
end
