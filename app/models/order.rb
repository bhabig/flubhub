class Order < ActiveRecord::Base
  has_many :items
  belongs_to :user

  def total
    prices = self.items.map{|i| i.price}
    self.total = prices.inject(0){|total, price| total += price}
  end

  def order_finished
    self.order_time = Time.now.strftime("%A, %B %d %Y at %I:%M%p")
  end

  def finished_order
    self.order_placed = true
  end
end
