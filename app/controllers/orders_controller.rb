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
      erb :'orders/new'
    else
      redirect "/login"
    end
  end

  post '/orders' do
    @user = current_user
    @order = Order.create(params[:order])
    if !@order.items.empty? && logged_in?
      @order.order_finished
      @order.finished_order
      @order.total
    end
    @order.save
    @user.orders << @order

    flash[:message] = "Thank You! Your Order Has Successfully Been Placed. You Can Expect Your Order In 30 - 45 Minutes!"

    redirect :"/orders/#{@order.id}"
  end

  get '/orders/:id' do
    @user = current_user
    @order = Order.find_by_id(params[:id])
    if @order.user_id == @user.id && @order.order_placed == true
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
