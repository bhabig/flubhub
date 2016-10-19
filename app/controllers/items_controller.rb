class ItemsController < ApplicationController

  get '/items/:id/:id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:id])
      erb :'items/show_item'
    else
      redirect '/login'
    end
  end

  get '/items/:id/:id/edit' do
    if logged_in?
      @order = Order.find_by_id(params[:captures][0].to_i)
      @item = Item.find_by_id(params[:id])
      Item.sorter
      erb :'items/edit_custom_item'
    else
      redirect '/login'
    end
  end

  patch '/items/:id/:id' do
    @order = Order.find_by_id(params[:captures][0].to_i)
    @item = Item.find_by_id(params[:id])
    if @item
      @item.update(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11)
      @item.save
    end
    redirect "/items/#{@order.id}/#{@item.id}"
  end

end
