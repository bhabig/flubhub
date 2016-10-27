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
    user = current_user
    missing_fields_check
    order = []
    if Order.quantity_check(params) == true
      Order.post_new_order(params, user, order)
      order[0].time_started
      @user.orders << order[0]
    else
      flash[:message] = "Sorry #{@user.username.capitalize}! Quantity must be a whole number greater than or equal to two."
      redirect "/orders/new"
    end
    redirect "/orders/#{order[0].id}"
  end

  get '/orders/:order_id' do #move logic to Order model (count method)
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

  get '/orders/:order_id/continue_shopping' do #move logic to Order model (count method)
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

  get '/orders/:order_id/change_item_quantities' do #move logic to Order model (count mehtod)
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

    @order.time_started                   #put
    @order.items << order.items           #these
    @order.total                          #in
    @order.save                           #a
    @user.orders << @order                #helper?
                                          #^used in post /orders too
    redirect "/placed_order/#{@order.id}"
  end

  patch '/orders/:order_id' do #LOTS TO MOVE TO ORDER MODEL, BUT ALSO LOTS THAT CAN BE DONE WITH
    user = current_user
    edit = Order.find_by_id(params[:order_id])
    order = []

    Order.post_new_order(params, user, order)

    order[0].total
    order[0].save

    redirect "/orders/#{order[0].id}"
  end

  post '/orders/:order_id/:item_id/remove_from_order' do # logic to Order model

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
        redirect "/orders/#{@order.id}"
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

  helpers do
    def missing_fields_check
      @user = current_user
      if !params[:order] && params[:item][:name] != "" && !params[:ingredients]
        flash[:message] = "Sorry #{@user.username.capitalize}! Your Custom Flurger Must Have Ingredients"
        redirect 'orders/new'
      elsif !params[:ingredients] && !params[:order] && params[:item][:name] == ""
        flash[:message] = "Sorry #{@user.username.capitalize}! Your Florder Must Have Items!"
        redirect 'orders/new'
      end
    end
  end
end
