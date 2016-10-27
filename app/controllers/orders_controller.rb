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
    Order.post_new_order(params, session)
  end

  get '/orders/:order_id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:order_id])
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

  get '/orders/:order_id/continue_shopping' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:order_id])
      if @order.user_id == @user.id
        Item.sorter
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}
        erb :'orders/continue_shopping'
      end
    else
      redirect '/login'
    end
  end

  get '/orders/:order_id/change_item_quantities' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:order_id])
      if @order.user_id == @user.id
        Item.sorter
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}
        erb :'orders/change_item_quantities'
      end
    else
      redirect '/login'
    end
  end

  get '/orders/:order_id/place_again' do
    @user = current_user
    order = Order.find_by_id(params[:order_id])
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

  patch '/orders/:order_id' do
    @user = current_user
    @order = Order.find_by_id(params[:order_id])
    if !params[:order_quantities].find{|q| q[/[a-zA-Z]+/]} && !params[:item][:quantity][/[a-zA-Z]+/]
      if params[:order]
        params[:order][:item_ids].each.with_index do |id, i|
          if params[:order_quantities][id.to_i-1].to_i >= 2
            (params[:order_quantities][id.to_i-1].to_i).times do
              @order.items << Item.find_by_id(id)
            end
          else
            @order.items << Item.find_by_id(id)
          end
        end
        if params[:ingredients] && params[:item][:quantity] == ""
      		@order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
        elsif params[:ingredients] && params[:item][:quantity] != ""
          item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
          params[:item][:quantity].to_i.times do
            @order.items << item
          end
        elsif !params[:ingredients] && params[:item][:name] != ""
          flash[:message] = "Sorry #{@user.username.capitalize}! Your Custom Flurger Must Have Ingredients"
          redirect :"/orders/#{@order.id}/continue_shopping"
        end
      elsif params[:ingredients] && !params[:order]
        if params[:ingredients] && params[:item][:quantity] == ""
          @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11)
        elsif params[:ingredients] && params[:item][:quantity] != ""
          item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11)
          params[:item][:quantity].to_i.times do
            @order.items << item
          end
        end
      elsif !params[:order] && params[:item][:name] != "" && !params[:ingredients]
        flash[:message] = "Sorry #{@user.username.capitalize}! Your Custom Flurger Must Have Ingredients"
        redirect 'orders/new'
      elsif !params[:ingredients] && !params[:order] && params[:item][:name] == ""
        flash[:message] = "Sorry #{@user.username.capitalize}! You Have Not Selected Any Items To Add. Please Add Items Or Click 'Cancel Order'"
        redirect :"/orders/#{@order.id}/continue_shopping"
      end
    else
      flash[:message] = "Sorry #{@user.username.capitalize}! Quantity must be a whole number greater than or equal to two."
      redirect :"/orders/#{@order.id}/continue_shopping"
    end

    @order.total
    @order.save

    redirect "/orders/#{@order.id}"
  end

  post '/orders/:order_id/:item_id/remove_from_order' do

    @order = Order.find_by_id(params[:captures][0].to_i)
    @item = Item.find_by_id(params[:captures][1].to_i)

    if !@order.items.empty?
      if @order && @item && params[:quantity].to_i >= 0
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}
        @order.items.delete(@item)
        params[:quantity].to_i.times do
          @order.items << @item
          @order.save
        end
      elsif !params[:quantity]
        x = @order.items.map{|i| i.name}
        @counts = x.each_with_object(Hash.new(0)) {|item,counts| counts[item] += 1}
        @order.items.delete(@item)
        @order.save
      end
      if @order.items.empty?
        redirect "/orders/#{@order.id}/continue_shopping"
      else
        redirect "/orders/#{@order.id}"
      end
    end
  end


  get '/placed_order/:order_id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:order_id])
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


  delete '/orders/:order_id/delete' do
    @order = Order.find_by_id(params[:order_id])
    @order.destroy
    redirect '/user'
  end

  get '/delete_all' do
    if logged_in?
      @user = current_user
      @user.orders.clear
      Order.all.map{|o| o.destroy if o.user_id == @user.id}
      redirect '/user'
    else
      redirect '/login'
    end
  end
end
