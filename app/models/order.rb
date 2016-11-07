class Order < ActiveRecord::Base

  has_many :quantities
  has_many :items, through: :quantities
  belongs_to :user

  def total_order(instance_storage=nil)
    prices = self.items.map do |i|
      q = i.quantities.where(order_id: self.id)
      i.price * q[0].amount
    end
    self.total = prices.inject(0){|total, price| total += price}
  end

  def time_started
    self.order_time = Time.now.strftime("%A, %B %d %Y at %I:%M%p")
  end

  def order_completed
    self.order_placed = true
  end

  def item_attributes=(params)
    @q = []
    params.each do |k, v|
      if v["amount"] != 0 && !v["amount"][/[a-zA-Z]+/] && v["id"]
        @q << self.quantities.build(item_id: v["id"].to_i, amount: (v["amount"] == "" ? 1 : v["amount"].to_i))
      end
    end
  end

  def item_attributes
    @q
  end

  def self.post_or_patch_order(params, current_user, instance_storage, existing_order=nil)
    self.order_with_preset(params, current_user, instance_storage, existing_order)
    self.custom_items_only(params, current_user, instance_storage, existing_order)
    @order.total_order(instance_storage)
    @order.save
    instance_storage << @order
  end

  def self.order_with_preset(params, current_user, instance_storage, existing_order=nil)
    if params[:order][:item_attributes].find{|id, hash| hash.include?("id")}
      self.create_order_add_items(params, instance_storage, existing_order, current_user)
      self.add_customs(params)
      if !params[:ingredients] && params[:item][:name] != ""
        return false
      end
    end
  end

  def self.create_order_add_items(params, instance_storage, existing_order=nil, current_user)
    existing_order_storage = []
    if existing_order == nil
      self.create_new_order(params, instance_storage, existing_order_storage, existing_order, current_user)
    else
      self.update_existing_order(params, instance_storage, existing_order_storage, existing_order, current_user)
    end
    @order = existing_order_storage[0]
    @order.save
    instance_storage << @order
  end

  def self.create_new_order(params, instance_storage, existing_order_storage, existing_order=nil, current_user)
    existing_order = Order.create(params[:order])
    existing_order.save
    existing_order_storage << existing_order
  end

  def self.update_logic(params, q=nil, id=nil, existing_order=nil, item=nil)
    if !q.empty? #innermost
      x = params[:order][:item_attributes][id]["amount"] == "" ? 1 : params[:order][:item_attributes][id]["amount"].to_i
      new_amount = q[0].amount + x
      q[0].update(amount: new_amount)
      q[0].save
    else #innermost
      quantity = Quantity.create_quantity(params, existing_order, item)
    end
  end

  def self.update_existing_order(params, instance_storage, existing_order_storage, existing_order=nil, current_user) #finda way to clean this up - extract param safety checks & possible make each innermost condition its own method & quantity.create should have its own method
    if params[:order][:item_attributes].find{|id, hash| hash.include?("id")}
      params[:order][:item_attributes].each do |id, hash|
        if hash.include?("id")
          item = Item.find_by_id(id.to_i)
          q = item.quantities.where(order_id: existing_order.id)
          self.update_logic(params, q, id, existing_order, item)
        end
      end
      existing_order.save
      existing_order_storage << existing_order
    end
  end

  def self.add_customs(params)
    if params[:ingredients]
      custom_item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
      order = @order
      quantity = Quantity.create_quantity(params, order, custom_item)
      @order = order
      @order.items << custom_item
    end
  end

  def self.custom_only_params(params)
    params[:ingredients] && !params[:order][:item_attributes].find{|id, hash| hash.include?("id")}
  end

  def self.custom_item_creation(params, instance_storage, existing_order=nil)
    custom_item = Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
    order = @order
    quantity = Quantity.create_quantity(params, order, custom_item)
    @order = order

    existing_order.items << custom_item
    @order = existing_order
    instance_storage << @order
  end

  def self.custom_items_only(params, current_user, instance_storage, existing_order=nil)
    if existing_order == nil
      if self.custom_only_params(params) #inner
        existing_order = Order.create(user_id: current_user.id)
        self.custom_item_creation(params, instance_storage, existing_order)
      end
    else
      if self.custom_only_params(params) #inner
        self.custom_item_creation(params, instance_storage, existing_order)
      end
    end
  end

  def self.item_quantity_updater_delete_params(params, existing_order=nil, item=nil)
    (existing_order && item && !params[:item_attributes]) || (existing_order && item && params[:item_attributes] && params[:item_attributes]["amount"].to_i == 0)
  end

  def self.item_quantity_updater_change_params(params, existing_order=nil, item=nil)
    existing_order && item && params[:item_attributes] && params[:item_attributes]["amount"].to_i >= 1
  end

  def self.item_quantity_updater(params, existing_order=nil, item=nil, instance_storage)
    if self.item_quantity_updater_delete_params(params, existing_order, item)
      existing_order.items.delete(item)
    elsif self.item_quantity_updater_change_params(params, existing_order, item)
      q = item.quantities.where(order_id: existing_order.id)
      q[0].update(amount: params[:item_attributes]["amount"].to_i)
    end
    existing_order.total_order
    existing_order.save
    instance_storage << existing_order
  end

  def self.quantity_check(params)
    !params[:item][:item_attributes][:amount][/[a-zA-Z]+/] && !params[:order][:item_attributes].find{|k,vh| vh["amount"][/[a-zA-Z]+/]} ? true : false
  end
end
