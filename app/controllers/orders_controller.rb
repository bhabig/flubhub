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
      params[:order][:item_ids].each.with_index do |id, i|
        if params[:quantity][id.to_i-1].to_i
          (params[:quantity][id.to_i-1].to_i-1).times do
            @order.items << Item.find_by_id(id)
          end
        end
      end
    	if params[:ingredients] && params[:item][:quantity] == ""
    		@order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
      elsif params[:ingredients] && params[:item][:quantity] != ""
        params[:item][:quantity].to_i.times do
          @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
        end
    	end
    elsif params[:ingredients] && !params[:order]
      @order = Order.create(user_id: @user.id)
      if params[:ingredients] && params[:item][:quantity] == ""
    		@order.items = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
      elsif params[:ingredients] && params[:item][:quantity] != ""
        params[:item][:quantity].to_i.times do
          @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
        end
    	end
    end
    #binding.pry
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
      if @order.user_id == @user.id && !@order.items.empty?
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}

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
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}
        erb :'orders/edit'
      end
    else
      redirect '/login'
    end
  end

  get '/orders/:id/place_again' do
    @user = current_user
    order = Order.find_by_id(params[:id])
    if order
      @order = Order.new(user_id: order.attributes[:user_id])
    end

    @order.time_started
    @order.items << order.items
    @order.total
    @order.save
    @user.orders << @order

    redirect :"/placed_order/#{@order.id}"
  end

  patch '/orders/:id' do
    @user = current_user
    @order = Order.find_by_id(params[:id])
    if params[:order]
      @order.update(params[:order])
      if params[:ingredients] && params[:item][:quantity] == ""
    		@order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
      elsif params[:ingredients] && params[:item][:quantity] != ""
        params[:item][:quantity].to_i.times do
          @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
        end
    	end
    elsif !params[:order] && !params[:ingredients]
      @order.items.clear
      redirect '/user'
    elsif !params[:order] && params[:ingredients]
      item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 10.99)
    	@order = Order.create(user_id: @user.id)
    	@order.items << item
      @order.time_started
      @user.orders << @order
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
