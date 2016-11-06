class Order < ActiveRecord::Base

  has_many :quantities
  has_many :items, through: :quantities
  belongs_to :user

  def total_order(instance_storage=nil)
    prices = self.items.map do |i|
      q = i.quantities.where(order_id: instance_storage[0].id)
      i.price * q.amount
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
        @q << self.quantities.build(item_id: v["id"].to_i, amount: v["amount"].to_i)
      end
    end
    binding.pry
  end

  def item_attributes
    @q
  end

  def self.post_or_patch_order(params, current_user, instance_storage, existing_order=nil)
    self.order_with_preset(params, instance_storage, existing_order, current_user)
    self.custom_items_only(params, instance_storage, existing_order, current_user)
    binding.pry
    @order.total_order(instance_storage)
    @order.save
    instance_storage << @order
  end

  def self.order_with_preset(params, instance_storage, existing_order=nil, current_user)#add logic to use new edit method?
    if params[:order]
      self.create_order_add_items(params, instance_storage, existing_order, current_user)
      self.add_customs(params)
      if !params[:ingredients] && params[:item][:name] != ""
        return false
      end
    end
  end

  def self.create_order_add_items(params, instance_storage, existing_order=nil, current_user)#add logic or create new method for editings
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

  def self.update_existing_order(params, instance_storage, existing_order_storage, existing_order=nil, current_user)
    if params[:order]
      existing_order.update(params[:order])
      existing_order.save
      existing_order_storage << existing_order
    elsif #what is this for again?
      existing_order_storage << existing_order
    end
  end

  def self.add_customs(params)#works as is for edit
    if params[:ingredients]
      @order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)
    end
  end

  def self.custom_only_params(params)
    params[:ingredients] && !params[:order]
  end

  def self.custom_item_creation(params, existing_order=nil)
    existing_order.items << Item.create(name: params[:item][:name]+" (your custom flurger)", ingredients: params[:ingredients].join(", "), price: 11.00)

    @order = existing_order
    instance_storage << @order
  end

  def self.custom_items_only(params, current_user, instance_storage, existing_order=nil) #break this down and clean it up!
    if existing_order == nil
      if self.custom_only_params(params)
        existing_order = Order.create(user_id: @user.id)
        self.custom_item_creation(params, existing_order=nil)
      end
    else
      if self.custom_only_params(params)
        self.custom_item_creation(params, existing_order=nil)
      end
    end
  end

  def self.quantity_check(params)
    !params[:item][:item_attributes][:amount][/[a-zA-Z]+/] && !params[:order][:item_attributes].find{|k,vh| vh["amount"][/[a-zA-Z]+/]} ? true : false
  end
end
