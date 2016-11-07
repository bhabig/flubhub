require 'rack-flash'

class OrdersController < ApplicationController
  use Rack::Flash

  get '/orders' do
    check_logged_in do
      @orders = Order.all
      redirect '/user'
    end
  end

  get '/orders/new' do
    check_logged_in do
      Item.sorter
      erb :'orders/new'
    end
  end

  post '/orders' do
    current_user
    instance_storage = []
    if Order.quantity_check(params) == true
      missing_fields_check
      Order.post_or_patch_order(params, current_user, instance_storage)
      instance_storage[0].time_started
      current_user.orders << instance_storage[0]
    else
      invalid_quantity_flash(current_user)
      redirect "/orders/new"
    end
    redirect "/orders/#{instance_storage[0].id}"
  end

  get '/orders/:order_id' do #move logic to Order model (count method)
    check_logged_in do
      find_order_match_user_id(current_user) do
        existing_order = @order
        if !existing_order.items.empty?
          @quantity = Quantity
          erb :'orders/show'
        else
          redirect '/user'
        end
      end
    end
  end

  get '/orders/:order_id/continue_shopping' do #move logic to Order model (count method)
    check_logged_in do
      find_order_match_user_id(current_user) do
        Item.sorter
        erb :'orders/continue_shopping'
      end
    end
  end

  get '/orders/:order_id/change_item_quantities' do #move logic to Order model (count mehtod)
    check_logged_in do
      find_order_match_user_id(current_user) do
        Item.sorter
        erb :'orders/change_item_quantities'
      end
    end
  end

  get '/orders/:order_id/place_again' do
    check_logged_in do
      find_order_match_user_id(current_user) do
        if @order
          order_again = Order.new(user_id: @order.attributes[:user_id])
        end
        order_again.total_order(order_again)
        order_again.time_started
        order_again.items << @order.items
        order_again.save
        @order_again = order_again
        current_user.orders << @order_again
        redirect "/placed_order/#{@order_again.id}"
      end
    end
  end

  patch '/orders/:order_id' do
    check_logged_in do
      existing_order = Order.find_by_id(params[:order_id])
      instance_storage = []
      missing_fields_check(existing_order)
      if Order.quantity_check(params) == true
        Order.post_or_patch_order(params, current_user, instance_storage, existing_order)
        instance_storage[0].total_order
        instance_storage[0].save
        redirect "/orders/#{instance_storage[0].id}"
      else
        invalid_quantity_flash(current_user)
        @order = existing_order
        redirect "/orders/#{@order.id}/continue_shopping"
      end
    end
  end

  post '/orders/:order_id/:item_id/remove_from_order' do # logic to Order model
    existing_order = Order.find_by_id(params[:captures][0].to_i)
    @item = Item.find_by_id(params[:captures][1].to_i)
    if !existing_order.items.empty?
      if existing_order && @item && !params[:item_attributes]
        existing_order.items.delete(@item)
      elsif existing_order && @item && params[:item_attributes] && params[:item_attributes]["amount"].to_i >= 0
        q = @item.quantities.where(order_id: existing_order.id)
        q[0].update(amount: params[:item_attributes]["amount"].to_i)
      end
      existing_order.total_order
      existing_order.save
      if existing_order.items.empty?
        redirect "/orders/#{existing_order.id}/continue_shopping"
      else
        redirect "/orders/#{existing_order.id}"
      end
    end
  end

  get '/placed_order/:order_id' do #recheck what you're doing here? probably
    check_logged_in do
      find_order_match_user_id(current_user) do
        if @order.total > 0
          @order.order_completed
          @order.save
          completed_order_flash(current_user)
          erb :'orders/completed_order'
        end
      end
    end
  end

  delete '/orders/:order_id/delete' do
    find_order_match_user_id(current_user) do
      @order.destroy
      redirect '/user'
    end
  end

  get '/delete_all' do
    check_logged_in do
      current_user.orders.clear
      Order.all.map{|o| o.destroy if o.user_id == current_user.id}
      redirect '/user'
    end
  end

  helpers do #have work do to on message variety
    def missing_fields_check(existing_order=nil)
      current_user
      flash_redirect_no_ingredients(existing_order)
      flash_redirect_no_items(existing_order)
    end

    def flash_redirect_no_items(existing_order=nil)
      if (!params[:order] && (params[:item][:name] != "" || !params[:item][:item_attributes][:amount].empty?) && !params[:ingredients]) || (!params[:ingredients] && !params[:order] && params[:item][:name] == "" && params[:item][:item_attributes][:amount].reject{|q| q.empty?}.empty?)
        if existing_order
          empty_order_flash(current_user)
          redirect "/orders/#{existing_order.id}/continue_shopping"
        else
          empty_order_flash(current_user)
          redirect 'orders/new'
        end
      end
    end

    def flash_redirect_no_ingredients(existing_order=nil)
      if !params[:ingredients] && params[:item][:name] != "" && params[:item][:item_attributes][:amount].empty? || !params[:ingredients] && params[:item][:name] == "" && !params[:item][:item_attributes][:amount].empty? || !params[:ingredients] && params[:item][:name] != "" && !params[:item][:quantity].empty?
        if existing_order
          missed_something_flash(current_user)
          redirect "/orders/#{existing_order.id}/continue_shopping"
        else
          missed_something_flash(current_user)
          redirect 'orders/new'
        end
      end
    end

    def missed_something_flash(current_user=nil)
      flash[:message] = "Sorry #{current_user.username.capitalize}! It looks like you didn't fill something in correctly."
    end

    def empty_order_flash(current_user=nil)
      flash[:message] = "Sorry #{current_user.username.capitalize}! Your Florder Must Have Items!"
    end

    def completed_order_flash(current_user=nil)
      flash[:message] = "Thank You #{current_user.username.capitalize}! Your order has been successfully placed. You Can Expect Your Order In 30 - 45 Minutes!"
    end

    def invalid_quantity_flash(current_user=nil)
      flash[:message] = "Sorry #{current_user.username.capitalize}! Quantity must be a whole number greater than or equal to two."
    end
  end
end
