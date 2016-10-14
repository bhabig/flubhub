class Order < ActiveRecord::Base
  has_many :items
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
end
