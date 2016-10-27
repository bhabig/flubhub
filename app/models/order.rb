class Order < ActiveRecord::Base

  has_many :quantities
  has_many :items, through: :quantities
  belongs_to :user

  def total
    prices = self.items.map{|i| i.price}
    self.total = prices.inject(0){|total, price| total += price}
  end

  def time_started
    self.order_time = Time.now.strftime("%A, %B %d %Y at %I:%M%p")
  end

  def order_completed
    self.order_placed = true
  end

  def self.post_new_order(params, session)
    @user = User.find_by_id(session[:user_id])
    if !params[:quantity].find{|q| q[/[a-zA-Z]+/]} && !params[:item][:quantity][/[a-zA-Z]+/]
      if params[:order]
      	@order = Order.create(params[:order])
        params[:order][:item_ids].each.with_index do |id, i|
          if params[:quantity][id.to_i-1].to_i >= 2
            (params[:quantity][id.to_i-1].to_i-1).times do
              @order.items << Item.find_by_id(id)
            end
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
          redirect :"/orders/new"
      	end
      elsif params[:ingredients] && !params[:order]
        @order = Order.create(user_id: @user.id)
        if params[:ingredients] && params[:item][:quantity] == ""
      		@order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
        elsif params[:ingredients] && params[:item][:quantity] != ""
          item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
          params[:item][:quantity].to_i.times do
            @order.items << item
          end
        end
      elsif !params[:order] && params[:item][:name] != "" && !params[:ingredients]
        flash[:message] = "Sorry #{@user.username.capitalize}! Your Custom Flurger Must Have Ingredients"
        redirect 'orders/new'
      elsif !params[:ingredients] && !params[:order] && params[:item][:name] == ""
        flash[:message] = "Sorry #{@user.username.capitalize}! Your Florder Must Have Items!"
        redirect :'orders/new'
      end
    else
      flash[:message] = "Sorry #{@user.username.capitalize}! Quantity must be a whole number greater than or equal to two."
      redirect :"/orders/new"
    end

    @order.time_started
    @order.total
    @order.save
    @user.orders << @order

    redirect :"/orders/#{@order.id}"
  end


end
