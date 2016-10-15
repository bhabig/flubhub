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

    @order.time_started
    @order.total
    @order.save
    @user.orders << @order

    redirect :"/orders/#{@order.id}"
  end

  get '/orders/:id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:id])
      if @order.user_id == @user.id && @order
        erb :'orders/show'
      else
        redirect '/user'
      end
    else
      redirect '/login'
    end
  end

  get '/orders/:id/edit' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:id])
      if @order.user_id == @user.id
        Item.sorter
        erb :'orders/edit'
      end
    else
      redirect '/login'
    end
  end

  patch '/orders/:id' do
    @user = current_user
    @order = Order.find_by_id(params[:id])
    if params[:order]
      @order.update(params[:order])
    elsif !params[:order] && !params[:ingredients]
      @order.items.clear

=begin
      if params[:ingredients]
        @order.items << Item.update(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
      end
    elsif params[:ingredients] && !params[:order]
    	item = Item.update(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
    	@order.update(user_id: @user.id)
    	@order.items << item
=end
      end

    @order.total
    @order.save

    redirect "/orders/#{@order.id}"
  end

  get '/placed_order/:id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:id])
      if @order.total > 0
        @order.order_completed
        @order.save
        flash[:message] = "Thank You #{@user.username.capitalize}! Your Order Has Successfully Been Placed. You Can Expect Your Order In 30 - 45 Minutes!"
        erb :'orders/completed_order'
      else
        flash[:message] = "Thank You #{@user.username.capitalize}! Your Order Has Successfully Been Placed. You Can Expect Your Order In 30 - 45 Minutes!"
        redirect :"/orders/#{@order.id}"
      end
    else
      redirect '/login'
    end
  end


  delete '/orders/:id/delete' do
    @order = Order.find_by_id(params[:id])
    @order.delete
    redirect '/user'
  end

  get '/delete_all' do
    if logged_in?
      @user = current_user
      @user.orders.clear
      Order.all.map{|o| o.delete if o.user_id == @user.id}
      redirect '/user'
    else
      redirect '/login'
    end
  end
end
