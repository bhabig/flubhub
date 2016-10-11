class UserOrder < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  def total
    prices = self.items.map{|i| i.price}
    prices.inject(0){|total, price| total += price}
  end

  def order_started
    Time.now.strftime("%A, %B %d %Y at %I:%M%p")
  end

  def order_placed?(status = false)
    status
  end


end
