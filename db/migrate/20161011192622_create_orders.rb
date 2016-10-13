class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.float :total, default: 0
      t.boolean :order_placed, default: false
      t.integer :user_id
      t.datetime :order_time, default: Time.now.strftime("%A, %B %d %Y at %I:%M%p")
    end
  end
end
