class Order < ActiveRecord::Base

  has_many :quantities
  has_many :items, through: :quantities
  belongs_to :user

  def total_order
    prices = self.items.map{|i| i.price}
    self.total = prices.inject(0){|total, price| total += price}
  end

  def time_started
    self.order_time = Time.now.strftime("%A, %B %d %Y at %I:%M%p")
  end

  def order_completed
    self.order_placed = true
  end

  def self.post_or_patch_order(params, user, instance_storage, existing_order=nil)
    @user = user

    self.order_with_preset(params, instance_storage, existing_order)
    self.custom_items_only(params, user, instance_storage)

    @order.total_order
    @order.save
    instance_storage << @order
  end

  def self.order_with_preset(params, instance_storage, existing_order=nil)#add logic to use new edit method?
    if params[:order]
      self.create_order_add_items(params, instance_storage, existing_order)
      self.add_customs(params)
      if !params[:ingredients] && params[:item][:name] != ""
        return false
      end
    end
  end

  def self.create_order_add_items(params, instance_storage, existing_order=nil)#add logic or create new method for editings
    if existing_order == nil
      existing_order = Order.create(params[:order])
      params[:order][:item_ids].each.with_index do |id, i| #redo this mendel's way - interpolation in the form where quantities[] is
        if params[:quantity][id.to_i-1].to_i >= 2
          (params[:quantity][id.to_i-1].to_i-1).times do
            existing_order.items << Item.find_by_id(id)
          end
        end
      end
    else
      params[:order][:item_ids].each.with_index do |id, i| #redo this mendel's way - interpolation in the form where quantities[] isy
        if params[:quantity][i].to_i >= 2
          params[:quantity][i].to_i.times do
            existing_order.items << Item.find_by_id(id)
          end
        else
          existing_order.items << Item.find_by_id(id)
        end
      end
    end
    @order = existing_order
    @order.save
    instance_storage << @order
  end

  def self.add_customs(params)#works as is for edit
    if params[:ingredients] && params[:item][:quantity] == ""
      @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
    elsif params[:ingredients] && params[:item][:quantity] != ""
      item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
      params[:item][:quantity].to_i.times do
        @order.items << item
      end
    end
  end



  def self.custom_items_only(params, user, instance_storage)
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
      instance_storage << @order
    end
  end

  def self.quantity_check(params)
    !params[:quantity].find{|q| q[/[a-zA-Z]+/]} && !params[:item][:quantity][/[a-zA-Z]+/] ? true : false
  end
end
