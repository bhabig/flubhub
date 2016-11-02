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

  def self.post_or_patch_order(params, current_user, instance_storage, existing_order=nil)
    self.order_with_preset(params, instance_storage, existing_order)
    self.custom_items_only(params, current_user, instance_storage, existing_order)

    @order.total_order
    @order.save
    instance_storage << @order
  end

  def item_attributes=(params)
    params.each do |k, v|
      #if v[:id] && v[:amount] is valid?
      self.quantities.build(item_id: v["id"], amount: v )
    end
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

  def self.create_new_order(params, instance_storage, existing_order_storage, existing_order=nil)
    existing_order = Order.create(params[:order])
    params[:order][:item_ids].each.with_index do |id, i| #redo this mendel's way - interpolation in the form where quantities[] is
      if params[:quantity][id.to_i-1].to_i >= 2
        (params[:quantity][id.to_i-1].to_i-1).times do
          existing_order.items << Item.find_by_id(id)
        end
      end
    end
    existing_order_storage << existing_order
  end

  def self.update_existing_order(params, instance_storage, existing_order_storage, existing_order=nil)
    params[:order][:item_ids].each.with_index do |id, i| #redo this mendel's way - interpolation in the form where quantities[] isy
      if params[:quantity][i].to_i >= 2
        params[:quantity][i].to_i.times do
          existing_order.items << Item.find_by_id(id)
        end
      else
        existing_order.items << Item.find_by_id(id)
      end
    end
    existing_order_storage << existing_order
  end

  def self.create_order_add_items(params, instance_storage, existing_order=nil)#add logic or create new method for editings
    existing_order_storage = []
    if existing_order == nil
      self.create_new_order(params, instance_storage, existing_order_storage, existing_order)
    else
      self.update_existing_order(params, instance_storage, existing_order_storage, existing_order)
    end
    @order = existing_order_storage[0]
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

  def self.custom_items_only(params, user, instance_storage, existing_order=nil) #break this down and clean it up!
    @user = user
    if existing_order == nil
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
    else
      if params[:ingredients] && !params[:order]
        if params[:ingredients] && params[:item][:quantity] == ""
          existing_order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
        elsif params[:ingredients] && params[:item][:quantity] != ""
          item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
          params[:item][:quantity].to_i.times do
            existing_order.items << item
          end
        end
        @order = existing_order
        instance_storage << @order
      end
    end
  end

  def self.quantity_check(params)
    !params[:quantity].find{|q| q[/[a-zA-Z]+/]} && !params[:item][:quantity][/[a-zA-Z]+/] ? true : false
  end
end
