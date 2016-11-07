class Quantity < ActiveRecord::Base

  belongs_to :order
  belongs_to :item

  def self.create_quantity(params, order=nil, custom_item=nil)
    self.create(order_id: order.id, item_id: custom_item.id, amount: params[:item][:item_attributes][:amount] == "" ? 1 : params[:item][:item_attributes][:amount].to_i)
  end

end
