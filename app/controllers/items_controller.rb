class ItemsController < ApplicationController

  get '/items/:order_id/:item_id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:item_id])
      erb :'items/show_item'
    else
      redirect '/login'
    end
  end

  get '/items/:order_id/:item_id/edit' do
    if logged_in?
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:item_id])
      Item.sorter
      erb :'items/edit_custom_item'
    else
      redirect '/login'
    end
  end

  patch '/items/:order_id/:item_id' do
    @order = Order.find_by_id(params[:captures][0].to_i)
    @item = Item.find_by_id(params[:item_id])
    if @item
      @item.update(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
      @item.save
    end
    redirect "/items/#{@order.id}/#{@item.id}"
  end

end
