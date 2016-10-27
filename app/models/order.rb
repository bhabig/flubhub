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

  def self.post_new_order(params, user, order)
    @user = user

    self.order_with_preset(params, order)
    self.custom_items_only(params, user, order)

    @order.total
    @order.save
    order << @order
  end

  def self.order_with_preset(params, order)
    if params[:order]
      self.create_order_add_items(params, order)
      self.add_customs(params)
      if !params[:ingredients] && params[:item][:name] != ""
        return false
      end
    end
  end

  def self.create_order_add_items(params, order)
    @order = self.create(params[:order])
    params[:order][:item_ids].each.with_index do |id, i| #redo this mendel's way - interpolation in the form where quantities[] is
      if params[:quantity][id.to_i-1].to_i >= 2
        (params[:quantity][id.to_i-1].to_i-1).times do
          @order.items << Item.find_by_id(id)
        end
      end
    end
    order << @order
  end

  def self.add_customs(params)
    if params[:ingredients] && params[:item][:quantity] == ""
      @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
    elsif params[:ingredients] && params[:item][:quantity] != ""
      item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
      params[:item][:quantity].to_i.times do
        @order.items << item
      end
    end
  end



  def self.custom_items_only(params, user, order)
    @user = user
    if params[:ingredients] && !params[:order]
      @order = Order.create(user_id: @user.id)
      if params[:ingredients] && params[:item][:quantity] == ""
        @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
      elsif params[:ingredients] && params[:item][:quantity] != ""
        item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
        params[:item][:quantity].to_i.times do
          @order.items << item
        end
      end
      order << @order
    end
  end

  def self.quantity_check(params)
    !params[:quantity].find{|q| q[/[a-zA-Z]+/]} && !params[:item][:quantity][/[a-zA-Z]+/] ? true : false
  end
end
