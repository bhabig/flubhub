class ItemsController < ApplicationController

  get '/items/:id/:id' do
    if logged_in?
      @user = current_user
      @order = Order.find_by_id(params[:id])
      @item = Item.find_by_id(params[:captures][0].to_i)
      erb :'items/show_item'
    else
      redirect '/login'
    end
  end

  get '/items/:id/:id/edit' do
    erb :'items/edit_custom_item'
  end

  patch '/items/:id' do

  end

end
