require 'rack-flash'

class OrdersController < ApplicationController
  use Rack::Flash

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
      Item.sorter
      erb :'orders/new'
    else
      redirect "/login"
    end
  end

  post '/orders' do
    @user = current_user
    if params[:order]
    	@order = Order.create(params[:order])
    	if params[:ingredients]
    		@order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
    	end
    elsif params[:ingredients] && !params[:order]
    	item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
    	@order = Order.create(user_id: @user.id)
    	@order.items << item
    end
    @order.order_completed
    @order.time_started
    @order.total
    @order.save
    @user.orders << @order
    	
    redirect :"/orders/#{@order.id}"
  end

  get '/orders/:id' do
    @user = current_user
    @order = Order.find_by_id(params[:id])
    if @order.user_id == @user.id && @order.order_completed == true
      erb :'orders/show'
    else
      redirect :"/orders/#{@order.id}/edit"
    end
  end

  get '/orders/:id/edit' do

  end

  patch '/orders/:id' do

  end

  delete '/orders/:id/delete' do
    @order = Order.find_by_id(params[:id])
    @order.delete
    redirect '/user'
  end
end
