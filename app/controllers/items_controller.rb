class ItemsController < ApplicationController

  get '/items/:order_id/:item_id' do
    check_logged_in do
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:item_id])
      erb :'items/show_item'
    end
  end

  get '/items/:order_id/:item_id/edit' do
    check_logged_in do
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:item_id])
      Item.sorter
      erb :'items/edit_custom_item'
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
