class CreateUserOrders < ActiveRecord::Migration
  def change
    create_table :user_orders do |t|
      t.integer :user_id
      t.integer :item_id
    end
  end
end
